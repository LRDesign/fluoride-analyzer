require 'fluoride-analyzer'

module Fluoride
  module Analyzer
    class Railtie < ::Rails::Railtie
      config.fluoride = ActiveSupport::OrderedOptions.new
      config.fluoride.directory = "fluoride-collector"

      rake_tasks do
        require 'fluoride-analyzer/tasklib'

        Fluoride::Analyzer::Tasklib.new do |task|
          task.limit = config.fluoride.results_limit
        end
      end
    end
  end
end
