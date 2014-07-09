require 'fluoride-analyzer'
require 'rack'
require 'yaml'
#Also: Rails and ActionDispatch::Request

module Fluoride::Analyzer
  class Parser
    attr_accessor :files, :limit, :target_path
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
      p record
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

    RoutePattern = Struct.new(:route, :matches, :params, :path_spec, :segment_keys)

    class Patterner
      def self.for(rails_routes)
        if rails_routes.respond_to? :recognize_path
          Rails4.new(rails_routes)
        else
          Rails3.new(rails_routes)
        end
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

      def initialize(rails_routes)
        @rails_routes = rails_routes
      end
      attr_reader :rails_routes

      def build_request(result_env)
        ActionDispatch::Request.new(base_env.merge(request_env))
      end

      def route_map
        @route_map ||=
          begin
            ad_routes_array   = rails_routes.routes
            rack_routes_array = rails_routes.set.instance_eval{ @routes }
            Hash[ rack_routes_array.zip(ad_routes_array) ]
          end
      end

      def route_set
        @route_set ||=
          begin
            set = rails_routes.set
            set
          end
      end

      class Rails3 < Patterner
        def build(env)
          req = build_request(env)
          route, matches, params = route_set.recognize(req)

          path_spec = :unrecognized
          segment_keys = {}

          if route_map.has_key?(route)
            rails_route = route_map[route]
            path_spec = rails_route.path
            segment_keys = rails_route.segment_keys
          end

          RoutePattern.new(route, matches, params, path_spec, segment_keys)
        end
      end

      class Rails4 < Patterner
        def route_set
          @route_set ||=
            begin
              set = Rails.application.routes.router
              set
            end
        end

        def build_request(request_env)
          ActionDispatch::Request.new(base_env.merge(request_env))
        end

        def build(env)
          req = build_request(env)
          pattern = nil
          route_set.recognize(req) do |route, matches, params|
            rails_route = route_map[route]

            path_spec = :unrecognized
            segment_keys = {}

            if route_map.has_key?(route)
              rails_route = route_map[route]
              path_spec = rails_route.path.spec.to_s
              segment_keys = rails_route.segment_keys
            end

            pattern = RoutePattern.new(route, matches, params, path_spec, segment_keys)
          end
          pattern
        end
      end
    end

    def patterner
      @patterner ||= Patterner.for(Rails.application.routes)
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
        puts "\n#{__FILE__}:#{__LINE__} => #{record['request']['path'].inspect}"
        puts "\n#{__FILE__}:#{__LINE__} => #{route.inspect}"
        puts "\n#{__FILE__}:#{__LINE__} => #{[matches,params].pretty_inspect}" rescue nil
      else
        route_path = pattern.path_spec
        path_params = Hash[pattern.segment_keys.map do |key|
          [key, params[key]]
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
      p [file, ex, ex.backtrace[0..2]]
      @exceptions << [ex, file]
      raise
    end
  end
end
