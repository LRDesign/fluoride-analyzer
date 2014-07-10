require "action_controller/railtie"
require 'fluoride-analyzer/rails'

describe Fluoride::Analyzer::Railtie do
  let! :rails_application do
    Class.new(::Rails::Application).tap do |app|
      app.configure do
        config.active_support.deprecation = :stderr
        config.eager_load = false
      end
      app.initialize!
    end.load_tasks
  end

  after :each do
    Rails.application = nil #because Rails has ideas of it's own, silly thing
  end

  it "should add rake tasks" do
    expect(Rake::Task["fluoride:analyzer:rebuild_request_specs"]).not_to be_nil
  end
end
