require 'fluoride-analyzer'
require 'rack'
require 'yaml'
#Also: Rails and ActionDispatch::Request

module Fluoride::Analyzer
  class Parser
    attr_accessor :files, :limit, :target_path
    attr_reader :exceptions, :results

    def initialize
      @exceptions = []
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

    def route_map
      @route_map ||=
        begin
          ad_routes_array   = Rails.application.routes.routes
          rack_routes_array = Rails.application.routes.set.instance_eval{ @routes }
          Hash[ rack_routes_array.zip(ad_routes_array) ]
        end
    end

    def route_set
      @route_set ||=
        begin
          set = Rails.application.routes.set
          set
        end
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
      p record
      raise
    end

    def base_env
      @base_env ||= {
        "HTTP_REFERER" => '',
        "HTTP_COOKIE" => '',
        "HTTP_AUTHORIZATION" => '',
        "REQUEST_METHOD" => "GET",
        'HTTP_HOST' => '',
        'SERVER_NAME' => '',
        'SERVER_ADDR' => '',
        'SERVER_PORT' => '80',
        "SCRIPT_NAME" => '',
        "QUERY_STRING" => '',
        'rack.input' => '' #body
      }
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

    def collect_record(file, record, index)
      return if exclude?(record)

      request_env = {
        "REQUEST_METHOD" => record['request']['method'].to_s.upcase,
        "PATH_INFO"  => record['request']['path'],
      }
      unless request_env['REQUEST_METHOD'] == "GET"
        request_env['rack.input'] = StringIO.new(record['request']['body'])
      end

      req = ActionDispatch::Request.new(base_env.merge(request_env))
      route, matches, params = route_set.recognize(req)
      return if route.nil?

      rails_route = route_map[route]

      route_path = :unrecognized
      path_params = {}

      if rails_route.nil?
        puts "\n#{__FILE__}:#{__LINE__} => #{record['request']['path'].inspect}"
        puts "\n#{__FILE__}:#{__LINE__} => #{route.inspect}"
        puts "\n#{__FILE__}:#{__LINE__} => #{[matches,params].pretty_inspect}" rescue nil
      else
        route_path = rails_route.path
        path_params = Hash[rails_route.segment_keys.map do |key|
          [key, params[key]]
        end]
      end

      formatted_record = format_record(record, path_params).merge(post_params(record))

      self.results[route_path][record['request']['method']][record['response']['status']][formatted_record] << [file, index]
    end

    def parse_file(file)
      stream = YAML.load_stream(File.read(file))

      stream.documents.each_with_index do |record, index|
        collect_record(file, record, index)
      end
    rescue ArgumentError => ex
      @exceptions << [ex, file]
    rescue Exception => ex
      p [file, ex, ex.backtrace[0..2]]
      @exceptions << [ex, file]
      raise
    end

    def go
      files = self.files[0..limit]

      files.each do |file|
        parse_file(file)
      end

      File.open(target_path, 'w') do |outfile|
        outfile.write(YAML.dump(formatted_results))
      end
    end
  end
end
