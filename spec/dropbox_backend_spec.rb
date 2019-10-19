require_relative "../dropbox_backend"

describe DropboxBackend do
  before(:all) do
    @backend = DropboxBackend.new("abc", "def")
  end
end
