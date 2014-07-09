require 'erb'
require 'fluoride-analyzer/pattern-context'

module Fluoride::Analyzer
  class RequestTemplater
    def initialize

    end
    attr_accessor :template, :template_string, :target_dir, :results

    def template
      @template ||= ERB.new(template_string, nil, '<>')
    end

    def go
      results.each_pair do |pattern, statuses|
        context = PatternContext.new(pattern, statuses)

        path = File.join(target_dir, context.filename)
        contents = template.result(context_binding)

        yield(path, contents)

        File.open(File.join("spec/requests", context.filename), "w") do |spec_file|
          spec_file.write(template.result(context.binding))
        end
      end
    end
  end
end
