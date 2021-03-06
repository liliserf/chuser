ENV['RACK_ENV'] = 'test'
require File.join(File.dirname(__FILE__), '..', 'web/server.rb')

require 'sinatra'
require 'rack/test'
require 'dotenv'
require 'vcr'

Dotenv.load

# setup test environment
set :environment, :test
set :run, false
set :raise_errors, true
set :logging, false

def app
  Sinatra::Application
end

RSpec.configure do |config|
  config.include Rack::Test::Methods
end

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  c.hook_into :webmock # or :fakeweb
end
