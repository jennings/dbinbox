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
end
