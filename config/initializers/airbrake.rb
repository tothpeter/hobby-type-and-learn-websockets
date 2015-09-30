Airbrake.configure do |config|
  config.api_key = ENV['TAL_WEBSOCKETS_AIRBRAKE_API_KEY']
  config.host    = ENV['TAL_WEBSOCKETS_AIRBRAKE_HOST']
  config.port    = 443
  config.secure  = config.port == 443
  config.ignore_only = []
  config.environment_name = ENV['RACK_ENV'] || "development"
end