ruby '2.2.3'
source 'https://rubygems.org'

gem 'puma'
gem 'rack'
gem 'faye-websocket'
gem 'json'

group :production do
  gem 'airbrake'
end

group :development do
  gem 'capistrano'
  gem 'capistrano-bundler', require: false
  gem 'capistrano3-puma'
end

group :test do
  gem 'rspec'
  gem 'rspec-eventmachine'
end