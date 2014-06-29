require 'fluoride-analyzer'

module Fluoride::Analyzer
  class Request
    attr_accessor :request_hash

    def initialize
      @request_hash = {}
    end
  end
end
