module Fluoride::Analyzer
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
        if pattern.nil?
          pattern = RoutePattern.new(nil,nil,nil,nil,nil)
        end
        pattern
      end
    end
  end
end
