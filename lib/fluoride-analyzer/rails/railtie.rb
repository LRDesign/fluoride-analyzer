require 'fluoride-analyzer'

module Fluoride
  module Analyzer
    class Railtie < ::Rails::Railtie
      #config.fluoride.directory = "fluoride-collector"

      rake_tasks do
        # load '/path/to/task'
      end

    end
  end
end
