# Generated by cucumber-sinatra. (2014-06-23 13:22:14 -0700)

ENV['RACK_ENV'] = 'test'

require File.join(File.dirname(__FILE__), '..', '..', './canto.rb')

require 'capybara'
require 'capybara/cucumber'
require 'factory_girl'
require 'rspec'

# Require all factories from RSpec directory
require_all File.expand_path('../../../spec/factories', __FILE__)

Capybara.app = Canto

class CantoWorld
  include Capybara::DSL
  include RSpec::Expectations
  include RSpec::Matchers
end

World do
  CantoWorld.new
end