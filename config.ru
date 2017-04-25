require 'sinatra'
require 'secure_headers'

set :port, 8000
enable :sessions
disable :run, :reload

# Use DATABASE_URL from the environment if we have it, otherwise just use a
# default SQLite database.
set :database_url, ENV['DATABASE_URL'] || "sqlite3://#{File.join(Dir.pwd, "users.db")}"

# Dropbox API
set :dbkey,    ENV['DROPBOX_KEY']
set :dbsecret, ENV['DROPBOX_SECRET']

# If running as a single-instance, the default username is the one that /
# redirects to automatically.
set :default_username, ENV['DROPZONE_DEFAULT_USERNAME']

# Setting a registration password blocks new users unless they know the
# password.
set :registration_password, ENV['DROPZONE_REGISTRATION_PASSWORD']

use SecureHeaders::Middleware
SecureHeaders::Configuration.default do |config|
  config.cookies = {
    httponly: true,
    secure: true,
  }
  config.csp = {
    default_src: %w('self'),
    script_src: %w('self' https://maxcdn.bootstrapcdn.com https://code.jquery.com),
    style_src: %w('self' https://maxcdn.bootstrapcdn.com),
    font_src: %w(https://maxcdn.bootstrapcdn.com)
  }
end

require File.join(File.dirname(__FILE__), 'app')
set :protection, :except => [:remote_token, :frame_options, :json_csrf]
run Sinatra::Application
