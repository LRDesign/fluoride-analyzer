module Fluoride
  module Analyzer
    class ConfigurationError < ::StandardError
    end
  end
end

require 'fluoride-analyzer/config'
require 'fluoride-analyzer/rails' if defined?(Rails)
