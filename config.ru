require 'sinatra'

set :environment, :production
set :port, 3200
disable :run, :reload
#
# If running as a single-instance, the default username is the one that /
# redirects to automatically.
set :default_username, ENV['DROPZONE_DEFAULT_USERNAME']

require File.join(File.dirname(__FILE__), 'app')
set :protection, :except => [:remote_token, :frame_options, :json_csrf]
run Sinatra::Application
