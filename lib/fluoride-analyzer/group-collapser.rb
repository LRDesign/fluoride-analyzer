require 'fluoride-analyzer/group-context'

module Fluoride::Analyzer
  class GroupCollapser
    def initialize(pattern, letname_map, method, status, requests_list)
      @pattern = pattern
      @letname_map = letname_map
      @request_list = requests_list
      @method, @status = method, status
    end
    attr_reader :method, :status, :letname_map

    def stet_list
      []
    end

    def requests
      @request_list
    end

    def reduce_path(path, request)
      path = @pattern.dup
      request['path_params'].each_pair do |name, value|
        next if stet_list.include?(name)
        target_name = letname_map.fetch(name, name)
        path.sub!(/:#{name}/,"\#{#{target_name}}")
      end
      path
    end

    def reduce_query(query, request)
      ""
      #none captured (yet?)
    end

    def each_group_context
      path_tuples = requests.map do |request|
        [request['path'], request['query_params'], request]
      end

      reduced_hash = Hash.new{|h,k| h[k] = []}
      path_tuples.each do |path, query, request|
        reduced_hash[ [ reduce_path(path, request), reduce_query(query, request) ] ] << request
      end

      reduced_hash.each do |(path, query_params), requests|
      yield GroupContext.new(method, status, requests, path, query_params)
      end
    end
  end
end
