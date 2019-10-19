require 'sinatra'
require 'json'
require 'haml'
require 'yaml'
# database from http://datamapper.org/getting-started.html
require 'dm-core'
require 'dm-types'
require 'dm-migrations'
require 'dm-validations'

require_relative './dropbox_backend'

DataMapper.setup(:default, settings.database_url)
BACKEND = DropboxBackend.new(settings.dbkey, settings.dbsecret)

# from http://stackoverflow.com/questions/8414395/verb-agnostic-matching-in-sinatra
def self.get_or_post(url, &block)
  get(url, &block)
  post(url, &block)
end

class User
  terabyte = 1024 * 1024 * 1024 * 1024

  include DataMapper::Resource
  property :username, String, :key => true, :required => true, :unique => true, :format => /^\w+$/
  property :dropbox_account, Text
  property :dropbox_token, Text
  property :referral_link, String, :length => 250
  property :authenticated, Boolean
  property :display_name, String, :length => 250
  property :email, String, :length => 250
  property :uid, String
  property :country, String
  property :quota, Integer, :min => 0, :max => 50 * terabyte
  property :shared, Integer, :min => 0, :max => 50 * terabyte
  property :normal, Integer, :min => 0, :max => 50 * terabyte
  property :created_at, DateTime
  property :password, BCryptHash
end
# Automatically create the tables if they don't exist
DataMapper.auto_upgrade!

class Numeric
  def to_human
    return "empty" if self.zero?
    units = %w{bytes KB MB GB TB}
    e = (Math.log(self)/Math.log(1024)).floor
    s = "%.3f" % (to_f / 1024**e)
    s.sub(/\.?0*$/, " " + units[e])
  end
end

before do
  @require_registration_password = !(settings.registration_password.nil? || settings.registration_password.empty?)
  @errors = {}
end

# ----------------------------------------------

# user visits homepage
# user enters desired username
# app checks that username isn't already registered
# if yes -> redirect to home page with error message
# app stores dropbox_account and desired username in session
# dropbox authenticates
# app creates user from session's username, dbtoken, and info from /account/info
# doublechecks that username isn't taken
# app shows user registered page with link to their Dropzone

# person visits link
# app looks up access token based on username
#   if doesn't exist, show "user does not exist"
# if exists, look up access token and use that

get '/' do
  if settings.default_username && !settings.default_username.empty?
    redirect "/#{settings.default_username}"
  else
    haml :index
  end
end

def get_auth_redirect_url(action)
  logger.info "setting post_auth_action: '#{action}'"
  session[:post_auth_action] = action
  url('/auth_callback')
end

get '/auth_callback' do
  token = BACKEND.get_token(params[:code], url('/auth_callback'))
  session[:dropbox_account] = BACKEND.get_account(token).to_hash
  session[:dropbox_token] = token

  auth_action = session[:post_auth_action]
  if auth_action == :create
    create_user
  elsif auth_action == :admin
    auth_for_admin
  else
    logger.error "unknown post_auth_action: '#{auth_action}'"
    redirect url('/')
  end
end

def create_user
  logger.info "Creating account for \"#{session[:username]}\"."
  # the user has returned from Dropbox
  # we've been authorized, so now request an access_token
  dropbox_account = session[:dropbox_account]
  dropbox_token = session[:dropbox_token]

  # get info from dropbox
  account_info = BACKEND.get_account(dropbox_token)
  # quota = account_info["quota_info"]

  @user = User.create(
    :username        => session[:username],
    :dropbox_account => YAML.dump(dropbox_account),
    :dropbox_token   => dropbox_token,
    # :referral_link => account_info["referral_link"],
    :authenticated   => true,
    :display_name    => account_info.name.display_name,
    :uid             => account_info.account_id,
    # :quota         => quota["quota"],
    # :normal        => quota["normal"],
    # :shared        => quota["shared"],
    :created_at      => Time.now
  )

  if @user.saved?
    logger.info "\"#{session[:username]}\"'s account has been created."
    session[:registered] = true
    redirect url("/#{session{:username}}")
  else
    logger.info "\"#{session[:username]}\"'s account could not be created."
    logger.info @user
    @errors[:general] = "Sorry, your information couldn't be saved: #{@user.errors.map(&:to_s).join(', ')}. Please try again or report the issue to <a href='https://twitter.com/cgenco'>@cgenco</a>."
    haml :index
  end
end

def auth_for_admin
  redirect url('/admin')
end

# request a username
post '/' do
  username = params['username']
  logger.info "\"#{username}\" username requested"

  # if the user already exists and is currently authenticated
  # or if the requested username isn't composed of word characters
  # then return an error
  user = User.get(username)
  if !user.nil? && user.authenticated
    @errors[:username] = "Sorry! \"#{username}\" is already taken."
  elsif !(username =~ /^\w+$/)
    @errors[:username] = "Your username must only contain letters." if !(username =~ /^\w+$/)
  elsif username.empty?
    @errors[:username] = "Your username can't be blank! I need to use that one! D:"
  elsif username =~ /^admin|login|logout|delete|send$/
    @errors[:username] = "Nice try, smarty pants."
  end

  if @require_registration_password && settings.registration_password != params[:registration_password]
    @errors[:registration_password] = "Sorry, you must provide the right registration password to create an account."
  end

  return haml(:index) if @errors.any?

  session[:username] = username

  # send them out to authenticate us
  redirect BACKEND.get_authenticate_uri(get_auth_redirect_url(:create))
end

get "/login" do
  redirect BACKEND.get_authenticate_uri(get_auth_redirect_url(:admin))
end

get "/logout" do
  session.clear
  redirect "/"
end

get "/admin" do
  if session[:registered]
    # already registered; render the admin panel
    @user = User.get(session[:username])
    return haml :admin
  else
    if
      # just came from being authenticated from Dropbox
      # stash this user's username and update their session
      dropbox_account = session[:dropbox_account]
      dropbox_token = session[:dropbox_token]
      account = BACKEND.get_account(dropbox_token)
      @user = User.first(:uid => account.account_id)

      # update the user with the new session in case they're re-authenticating
      @user.update(
        dropbox_account: YAML.dump(dropbox_account),
        dropbox_token: dropbox_token,
      )

      session[:username] = @user.username
      session[:registered] = true
      haml :admin
    else
      # need to get authenticated by Dropbox first
      redirect url('/login')
    end
  end
end

post "/admin" do
  @user = User.get(session[:username])
  redirect url('/login') unless @user

  @user.update(:password => params[:access_code])
  return haml :admin
end

post "/delete" do
  if session[:registered]
    @user = User.get(session[:username])
    @user.destroy
    session.clear
    redirect url('/')
  else
    redirect url('/login')
  end
end

get_or_post '/send/:username/?*' do
  @subfolder = params[:splat].first

  # IE 9 and below tries to download the result if Content-Type is application/json
  content_type (request.user_agent && request.user_agent.index(/MSIE [6-9]/) ? 'text/plain' : :json)

  unless @user = User.get(params[:username])
    status 404
    return
  end

  redirect '/' unless @user.dropbox_account
  @dropbox_account = YAML.load(@user.dropbox_account)

  params[:files] ||= []

  if message = params["message"]
    logger.info "Sending text to /#{params[:username]}: \"#{params["message"]}\""
    puts "post /#{params['username']}/send_text"

    message = params["message"]
    # add header to message
    # use @env['REMOTE_ADDR'] if request.ip doesn't work
    message = "Uploaded #{Time.now.to_s} from #{request.ip}\r\n\r\n#{message}"

    filename = Time.new.strftime("%Y-%m-%d-%H.%M.%S")
    filename += " " + params["filename"] if params["filename"] && !params["filename"].empty?
    filename += ".txt"

    params[:files].push({:filename => filename, :message => message})
  end

  responses = params[:files].map do |file|
    begin
      # if things go normally, just return the hashed response
      response = BACKEND.upload(@user.dropbox_token, File.join(@subfolder || '', file[:filename]), file[:message] || file[:tempfile].read)
      {
        name: response.path_display.sub(/^\//, ''),
        size: response.size,
        human_size: response.size.to_human,
        delete_type: 'DELETE',
      }
    rescue => err
      logger.error err
      session[:registered] = false
      @user.authenticated  = false
      @user.save
      {
        :error       => "Client not authorized.",
        :error_class => err.class.name,
        :name        => file[:filename]
      }
    end
  end

  responses.to_json # an array of file description hashes
end

get "/:username/?*" do
  logger.info "/#{params[:username]}"
  @subfolder = params[:splat].first
  @user = User.get(params[:username])
  @action = "/send/" + params[:username] + (@subfolder ? "/" + @subfolder : "")
  if !@user
    @errors[:username] = "Username '#{params[:username]}' not found. Would you like to link it with a Dropbox account?"
    return haml :index
  end

  if @user.password.nil? || @user.password == params[:password]
    haml :upload
  else
    haml :enter_password
  end
end
