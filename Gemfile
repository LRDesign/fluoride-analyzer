# bundle install --gemfile Gemfile.ruby-1.8.7
# BUNDLE_GEMFILE='Gemfile.ruby-1.8.7' bundle <command>
raise "Refusing to run. Use the 1.8.7 Gemfile!" if RUBY_VERSION <= '1.8.7'

source "https://rubygems.org"

gem 'rspec'
gem 'rack'
gem 'stack_loop'
gem 'fuubar', "~> 2.0.0.rc1"
gem 'cadre'
gem 'rails', "~> 4.0.0"
gem 'corundum'

gemspec :name => "fluoride-analyzer" #points to default 'gem.gemspec'
