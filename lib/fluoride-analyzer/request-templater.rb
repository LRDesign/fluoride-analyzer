require 'erb'
require 'fluoride-analyzer/pattern-context'

module Fluoride::Analyzer
  class RequestTemplater
    def initialize

    end
    attr_accessor :template, :template_string, :template_path, :results

    def template_string
      @template_string ||=  File.read(template_path)
    end

    def template
      @template ||= ERB.new(template_string, nil, '<>')
    end

    def go
      results.each_pair do |pattern, statuses|
        context = PatternContext.new(pattern, statuses)

        File.open(File.join("spec/requests", context.filename), "w") do |spec_file|
          spec_file.write(template.result(context.binding))
        end
      end
    end
  end
end
