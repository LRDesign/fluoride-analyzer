FLUORIDE_PATH = 'fluoride-collector'
LIMIT = 2000

directory 'spec/requests'

task :parse_fluoride => 'paths.yml'

task :rebuild_request_specs => [:clobber_request_specs, :template_request_specs]

task :clobber_request_specs do
  sh("rm -rf spec/requests/*")
end

file 'results.yml' => FileList[ "#{FLUORIDE_PATH}/*.yml" ] do |task|
  Rake::Task[:environment].invoke
  parser = Fluoride::Analyzer::Parser.new
  parser.files = task.prerequisites.find_all do |prereq|
    File.file?(prereq) && __FILE__ != prereq
  end
  #parser.limit = LIMIT #XXX Uncomment to limit number of files parsed
  parser.target_path = task.name

  parser.go

  puts "Found #{parser.results.keys.length} unique requests"
end

require 'fluoride-analyzer/request-templater'
task :template_request_specs => ['spec/requests', 'results.yml'] do
  templater = Fluoride::Analyzer::RequestTemplater.new

  templater.template_path = File::join("../../../templates/request_spec.erb", __FILE__)
  templater.results = YAML.load(File.read('results.yml'))
  templater.go
end
