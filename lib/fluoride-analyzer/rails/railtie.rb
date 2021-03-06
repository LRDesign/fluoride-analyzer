require 'fluoride-analyzer'

module Fluoride
  module Analyzer
    class Railtie < ::Rails::Railtie
      config.fluoride_path = %w{
        .
        config
        ~/.config/fluoride
        ~/.fluoride
      }

      rake_tasks do
        require 'fluoride-analyzer/tasklib'

        paths = config.fluoride_path
        configs = Valise::define do
          paths.each do |path|
            ro path
          end
          ro(from_here("../../../default_configs"))

          handle "*.yaml", :yaml, :hash_merge
          handle "*.yml", :yaml, :hash_merge
        end

        analyzer_config = configs.contents("analyzer.yml")

        Fluoride::Analyzer::Tasklib.new do |task|
          task.from_hash(analyzer_config)
        end
      end
    end
  end
end
