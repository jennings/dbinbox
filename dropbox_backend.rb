require 'dropbox_api'

class DropboxBackend
  def initialize(key, secret)
    @key = key
    @secret = secret
  end

  def get_authenticate_uri(redirect_uri)
    auth = get_authenticator
    auth.authorize_url(redirect_uri: redirect_uri)
  end

  def get_token(code, redirect_uri)
    auth = get_authenticator
    token_info = auth.get_token(code, redirect_uri: redirect_uri)
    token_info.token
  end

  def get_account(token)
    client = get_client(token)
    acct = client.get_current_account
    {
      id: acct.account_id,
      display_name: acct.name.display_name,
    }
  end

  def upload(token, filename, data)
    client = get_client(token)
    client.upload(filename, data)
  end

  private

  def get_client(token)
    DropboxApi::Client.new(token)
  end

  def get_authenticator
    DropboxApi::Authenticator.new(@key, @secret)
  end
end
