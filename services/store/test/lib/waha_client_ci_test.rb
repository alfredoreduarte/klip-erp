require "test_helper"
require "webmock/minitest"

class WahaClientCiTest < ActiveSupport::TestCase
  setup do
    @client = WahaClient.new
  end

  test "handles WAHA unavailability gracefully in CI" do
    # Simulate WAHA being unavailable (like in CI)
    stub_request(:any, /http:\/\/waha:3000\/.*/)
      .to_return(status: 503, body: "Service Unavailable")

    # Test that session operations fail gracefully
    assert_raises(WahaClient::Error) do
      @client.start_session(name: "default")
    end

    # Test that message sending fails gracefully
    assert_raises(WahaClient::Error) do
      @client.send_text(phone_number: "1234567890", text: "Test message")
    end

    # Test that profile fetching fails gracefully
    assert_raises(WahaClient::Error) do
      @client.session_profile(session: "default")
    end
  end

  test "handles network timeouts gracefully" do
    # Simulate network timeout
    stub_request(:any, /http:\/\/waha:3000\/.*/)
      .to_timeout

    # Test that operations fail with appropriate errors
    assert_raises(WahaClient::Error) do
      @client.start_session(name: "default")
    end
  end

  test "handles malformed responses gracefully" do
    # Simulate a response that's not successful but has invalid JSON
    stub_request(:any, /http:\/\/waha:3000\/.*/)
      .to_return(status: 500, body: "invalid json", headers: { "Content-Type" => "application/json" })

    # Test that operations fail gracefully when WAHA returns an error
    assert_raises(WahaClient::Error) do
      @client.session_profile(session: "default")
    end
  end
end