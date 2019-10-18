require 'dropbox_api'

class DropboxBackend
  def initialize(key, secret)
    @key = key
    @secret = secret
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
end
