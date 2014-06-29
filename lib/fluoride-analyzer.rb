module Fluoride
  module Analyzer
    class ConfigurationError < ::StandardError
    end
  end
end

require 'fluoride-analyzer/config'
require 'fluoride-analyzer/request'
require 'fluoride-analyzer/request-processor'
require 'fluoride-analyzer/exchange-result'
require 'fluoride-analyzer/exception-result'
require 'fluoride-analyzer/result-collection'
require 'fluoride-analyzer/rails' if defined?(Rails)
