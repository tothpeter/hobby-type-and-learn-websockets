require 'rack'
require 'airbrake'
require './app'

require './config/initializers/airbrake'

use Airbrake::Rack
run App.new