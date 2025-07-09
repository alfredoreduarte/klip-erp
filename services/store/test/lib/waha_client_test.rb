require "test_helper"
require "waha_client"
require "webmock/minitest"

class WahaClientTest < ActiveSupport::TestCase
  def setup
    @client = WahaClient.new(base_url: "http://waha.test")
  end

  test "send_text posts correct payload" do
    stub = stub_request(:post, "http://waha.test/api/sendText")
           .with(body: hash_including(text: "Hola"))
           .to_return(status: 200, body: { success: true }.to_json)

    response = @client.send_text(phone_number: "595981234567", text: "Hola")
    assert_equal "{\"success\":true}", response
    assert_requested stub
  end
end