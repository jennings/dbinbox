require_relative "../dropbox_backend"


describe DropboxBackend do
  before(:all) do
    @backend = DropboxBackend.new("abc", "def")
  end

  describe "#get_client" do
    it "returns a Dropbox client" do
      client = @backend.get_client("foobar")
      expect(client).to be_instance_of(DropboxApi::Client)
    end
  end

  describe "#get_authenticator" do
    it "returns a Dropbox authenticator" do
      auth = @backend.get_authenticator
      expect(auth).to be_instance_of(DropboxApi::Authenticator)
    end
  end
end

describe DropboxBackend, "#get_authenticator" do
end
