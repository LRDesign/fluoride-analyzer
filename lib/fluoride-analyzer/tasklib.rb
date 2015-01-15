require 'fluoride-analyzer/request-templater'
require 'fluoride-analyzer/parser'
require 'mattock'

module Fluoride::Analyzer
  class Tasklib < ::Mattock::Tasklib
    default_namespace "fluoride:analyzer"

    setting :limit, nil
    dir( :fluoride, "fluoride",
        path( :results, "results.yml"),
        dir(  :request_recordings, "recorded-requests"),
        dir(  :request_specs, "spec/requests"))

    setting :recordings_list

    def resolve_configuration
      super
      resolve_paths
      self.recordings_list ||= FileList[ "#{request_recordings.abspath}/*.yml" ]
    end

    def define
      in_namespace do
        directory request_specs.abspath

        desc "Delete and rebuild request specs based on Fluoride collections"
        task :rebuild_request_specs => [:clobber_request_specs, :template_request_specs]

        task :clobber_request_specs do
          sh("rm -rf #{request_specs.abspath}/*")
        end

        file results.abspath => [:environment] + recordings_list do |task|
          puts "Searching for recordings in #{request_recordings.abspath}, where there are #{recordings_list.length} .yml files"

          parser = Fluoride::Analyzer::Parser.new

          recordings_list.find_all do |prereq|
            next unless File.file?(prereq) && __FILE__ != prereq
            parser.parse_stream(prereq, File.read(prereq))
          end

          parser.limit = limit

          File.open(results.abspath, "w") do |target_file|
            target_file.write(YAML.dump(parser.formatted_results))
          end

          puts "Found #{parser.formatted_results.keys.length} unique requests"
        end

        desc "Produce request specs that reproduce Fluoride collections"
        task :template_request_specs => [request_specs.abspath, results.abspath] do
          templater = Fluoride::Analyzer::RequestTemplater.new

          templater.template_string = File::read(File::expand_path(
            "../../../default_config/templates/request_spec.erb", __FILE__))
          templater.results = YAML.load(File.read(results.abspath))
          templater.go do |filename, contents|
            path = File.join(request_specs.abspath, filename)
            File.open(path, "w") do |spec_file|
              spec_file.write(contents)
            end
          end
        end
      end
    end
  end
end
