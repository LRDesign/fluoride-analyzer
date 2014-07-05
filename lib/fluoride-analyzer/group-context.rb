module Fluoride::Analyzer
  class GroupContext
    def initialize(method, status, requests, path, query_params)
      @method, @status_code, @requests, @path, @query_params = method, status, requests, path, query_params
    end
    attr_reader :method, :status_code

    def test_method
      @method.downcase
    end

    def status_description
      case @status_code.to_i
      when 300..399
        "Redirect"
      else
        "OK"
      end
    end

    def request_count
      @requests.inject(0) do |sum, request|
        sum + request['sources'].keys.length
      end
    end

    def example_source
      request['sources'].keys.first
    end

    def example_path
      request['path']
    end

    def request_spec_description
      "#@method #{spec_request_path}"
    end

    def should_what
      case @status_code.to_i
      when 300..399
        "redirect"
      else
        "succeed"
      end
    end

    def redirect_path
      request['redirect_location'].sub(%r[^https?://#{request['host']}], '')
    end

    def test_result
      case @status_code.to_i
      when 300..399
        ["response.should redirect_to(\"#{redirect_path}\")"]
      else
        ["response.should be_success", "response.status.should == 200"]
      end
    end

    def test_request(indent)
      indent = " " * indent
      test_request = "#{test_method} \"#{spec_request_path}\""
      if request.has_key? 'post_params'
        params = request['post_params'].pretty_inspect.split("\n")
        params = ([params[0]] + params[1..-1].map do |line|
          indent + line
        end).join("\n")
        test_request += ", #{params}"
      end
      test_request
    end

    def spec_request_path
      "#{@path}#{@query_params}"
    end

    private

    def request
      @requests.first
    end
  end
end
