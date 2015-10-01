ruby '2.2.3'
source 'https://rubygems.org'

gem 'puma'
gem 'rack'
gem 'faye-websocket'
gem 'json'
gem 'rspec-eventmachine'

group :production do
  gem 'airbrake'
end

group :development do
  gem 'capistrano'
  gem 'capistrano-bundler', require: false
  gem 'capistrano3-puma'
end