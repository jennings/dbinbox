require 'dropbox_api'

class DropboxBackend
  def initialize(key, secret)
    @key = key
    @secret = secret
  end

  def get_client(token)
    DropboxApi::Client.new(token)
  end

  def get_authenticator
    DropboxApi::Authenticator.new(@key, @secret)
  end
end
