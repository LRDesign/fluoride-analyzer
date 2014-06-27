require "action_controller/railtie"
require "rails/test_unit/railtie"
require 'fluoride-analyzer/rails'

describe Fluoride::Analyzer::Railtie do

  ENV["RAILS_ENV"] ||= 'test'

  def config(app)

  end

  let :rails_application do
    Class.new(::Rails::Application).tap do |app|
      app.configure do
        config.active_support.deprecation = :stderr
        config.eager_load = false
      end
      config(app)
      app.initialize!
    end
  end

  after :each do
    Rails.application = nil #because Rails has ideas of it's own, silly thing
  end

  it "should add rake tasks"

end
