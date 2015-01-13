# vim: set ft=ruby :
require 'corundum/tasklibs'

module Corundum
  Corundum::register_project(__FILE__)

  core = Core.new

  core.in_namespace do
    GemspecFiles.new(core) do |gsf|
      gsf.extra_files.include("default_config/**")
    end

    #Also available: 'unfinished': TODO and XXX
    ["debug", "profanity", "ableism", "racism"].each do |type|
      QuestionableContent.new(core) do |content|
        content.type = type
      end
    end
    rspec = RSpec.new(core)

    cov = SimpleCov.new(core, rspec) do |cov|
      cov.threshold = 81
    end

    gem = GemBuilding.new(core)
    cutter = GemCutter.new(core,gem)
    vc = Git.new(core) do |vc|
      vc.branch = "master"
    end
  end
end

task :default => [:release, :publish_docs]
