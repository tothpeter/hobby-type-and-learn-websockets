require './app'

if ENV['RACK_ENV'] == "production"
  require 'rack'
  require 'airbrake'
  require './config/initializers/airbrake'
  use Airbrake::Rack
end

run App.new