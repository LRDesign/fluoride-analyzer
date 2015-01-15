require 'fluoride-analyzer'
require 'rack'
require 'yaml'
require 'fluoride-analyzer/patterner'

#Also: Rails and ActionDispatch::Request

module Fluoride::Analyzer
  class Parser
    attr_accessor :files, :limit
    attr_reader :exceptions, :results, :counts

    def initialize
      @exceptions = []
      @counts = {
        :excluded => 0,
        :unrecognized => 0,
        :no_matching_route => 0,
        :exceptions => 0
      }
      @results = Hash.new do|results, pattern| #PATH PATTERN
        results[pattern] = Hash.new do |by_method, method| #METHOD
          by_method[method] = Hash.new do |records, status| #STATUS CODE
            records[status] = Hash.new do |record, key| #formatted record
              record[key] = []
            end
          end
        end
      end
      @limit = -1
    end

    def excluded_content_types
      [ %r[image], %r[text/css], %r[javascript], %r[shockwave] ]
    end

    def excluded_paths
      [ %r[^/images], %r[\.ttf\z], %r[\.woff\z] ]
    end

    def exclude?(record)
      return true if record['type'] == 'exception_raised'

      if excluded_content_types.any?{ |reg| reg =~ record['response']['headers']['Content-Type'] }
        return true
      end
      if excluded_paths.any?{|req| req =~ record['request']['path']}
        return true
      end
      return false
    rescue
      warn "Exception raised while filtering record: #{record.inspect}"
      raise
    end

    def format_record(record, path_params)
      {
        'path' => record['request']['path'],
        'query_params' => record['request']['query_params'],
        'content-type' => record['request']['content_type'],
        'path_params' => path_params,
        'redirect_location' => record['response']['headers']['Location'],
        'host' => record['request']['host']
        #'accept' => record['request']['accept']
      }
    end

    def formatted_results
      formatted = {}
      results.each do |pattern, methods|
        frmt_methods = formatted[pattern] = {}
        methods.each do |method, status|
          frmt_statuses = frmt_methods[method] = {}
          status.each do |code, requests|
            frmt_statuses[code] = requests.keys.map do |req_hash|
              hash = req_hash.dup
              hash['sources'] = Hash[requests[req_hash]]
              hash
            end
          end
        end
      end
      formatted
    end

    def post_params(record)
      return {} unless %w{POST PUT}.include?(record['request']['method'])
      unless record['request']['content_type'].nil? or
        %r[^application/x-www-form-urlencoded.*] =~ record['request']['content_type']
        return {}
      end

      form_hash = Rack::Utils.parse_nested_query(record['request']['body'])

      { 'post_params' => form_hash }
    end

    def patterner
      @patterner ||= Patterner.for(Rails.application.routes)
    end
    attr_writer :patterner

    def warnings
      @warnings ||= Hash.new do |h,k|
        warn k
        h[k] = true
      end
    end

    def warning(message)
      warnings[message]
    end

    def collect_record(file, record, index)
      if exclude?(record)
        @counts[:excluded] += 1
        return
      end

      request_env = {
        "REQUEST_METHOD" => record['request']['method'].to_s.upcase,
        "PATH_INFO"  => record['request']['path'],
      }
      unless request_env['REQUEST_METHOD'] == "GET"
        request_env['rack.input'] = StringIO.new(record['request']['body'])
      end

      pattern = patterner.build(request_env)

      route = pattern.route

      if route.nil?
        @counts[:unrecognized] += 1
        return
      end

      if pattern.path_spec == :unrecognized
        @counts[:no_matching_route] += 1
        warning "Unrecognized route: #{record['request']['method']} #{record['request']['path'].inspect}"
        return
      else
        route_path = pattern.path_spec
        path_params = Hash[pattern.segment_keys.map do |key|
          [key, pattern.params[key]]
        end]
      end

      formatted_record = format_record(record, path_params).merge(post_params(record))

      self.results[route_path][record['request']['method']][record['response']['status']][formatted_record] << [file, index]
    end

    def parse_stream(file, string)
      stream = YAML.load_stream(string)
      stream = stream.documents if stream.respond_to? :documents

      stream.each_with_index do |record, index|
        collect_record(file, record, index)
      end
    rescue ArgumentError => ex
      @exceptions << [ex, file]
    rescue Exception => ex
      @exceptions << [ex, file]
      raise
    end
  end
end
