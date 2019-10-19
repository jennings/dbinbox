source 'https://rubygems.org'

gem 'sinatra'
gem 'dropbox_api'
gem 'json'
gem 'haml'
gem 'secure_headers'

# database
gem 'dm-core'
gem 'dm-types', '>= 1.2.0'
gem 'dm-migrations'
gem 'dm-validations'

group :development do
  gem 'shotgun'
  gem 'rspec', '~> 3.9.0'
  gem 'guard-rspec', require: false
end

group :sqlite do
  gem 'dm-sqlite-adapter'
end

group :postgres do
  gem 'dm-postgres-adapter'
end

gem 'thin'
