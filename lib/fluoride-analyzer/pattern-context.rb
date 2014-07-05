require 'fluoride-analyzer/group-collapser'
require 'fluoride-analyzer/pattern-collapser'

module Fluoride::Analyzer
  class PatternContext
    def initialize(pattern, methods_hash)
      @pattern, @methods_hash = pattern, methods_hash
      @collapser = PatternCollapser.new(pattern, methods_hash)
    end
    attr_reader :pattern

    def each_status_group
      @methods_hash.each_pair do |method, hash|
        hash.each_pair do |status, requests|
          GroupCollapser.new(@collapser.pattern, @collapser.param_letname_map, method, status, requests).each_group_context do |context|
            yield context
          end
        end
      end
    end

    def param_fields
      @collapser.params_fields
    end

    def filename
      @collapser.pattern.gsub(%r{[:/().]+},'_').gsub(/^_|_$/, '') + "_spec.rb"
    end

    public :binding
  end
end
