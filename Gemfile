source 'https://rubygems.org'

gem 'sinatra'
gem 'json'
gem 'haml'
gem 'secure_headers'

# Backends
gem 'omniauth'
gem 'omniauth-oauth2'
gem 'dropbox_api'

# database
gem 'dm-core'
gem 'dm-types', '>= 1.2.0'
gem 'dm-migrations'
gem 'dm-validations'

group :development, :test do
  gem 'rspec', '~> 3.9.0'
  gem 'guard-rspec', require: false
  gem 'byebug'
end

group :development do
  gem 'shotgun'
end

group :sqlite do
  gem 'dm-sqlite-adapter'
end

group :postgres do
  gem 'dm-postgres-adapter'
end

gem 'thin'
