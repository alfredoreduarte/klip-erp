require "test_helper"
require "webmock/minitest"

class WahaIntegrationCiTest < ActionDispatch::IntegrationTest
  setup do
    # Clean up any existing data
    MessageReaction.delete_all
    MediaFile.delete_all
    Message.delete_all
    Chat.delete_all
    WahaSession.delete_all

    # Create test data
    @chat = Chat.create!(wa_id: "123456789@c.us")
    @waha_session = WahaSession.create!(name: "default")
    @chat.update!(waha_session: @waha_session)
  end

  test "application handles WAHA unavailability gracefully" do
    # Simulate WAHA being completely unavailable (like in CI)
    stub_request(:any, /http:\/\/waha:3000\/.*/)
      .to_return(status: 503, body: "Service Unavailable")

    # Test that session creation fails gracefully
    assert_no_difference "WahaSession.count" do
      post "/waha/sessions", params: { name: "default" }
      assert_redirected_to waha_sessions_path
    end

    # Test that message sending fails gracefully
    assert_no_difference "Message.count" do
      post chat_messages_path(@chat), params: { message: { body: "Test message" } }
      assert_redirected_to chat_path(@chat)
    end

    # Test that chat sync fails gracefully
    assert_nothing_raised do
      @chat.sync_messages_from_waha!
    end
    assert_equal 0, @chat.messages.count
  end

  test "application handles network timeouts gracefully" do
    # Simulate network timeouts
    stub_request(:any, /http:\/\/waha:3000\/.*/)
      .to_timeout

    # Test that operations fail gracefully
    assert_no_difference "WahaSession.count" do
      post "/waha/sessions", params: { name: "default" }
      assert_redirected_to waha_sessions_path
    end

    assert_no_difference "Message.count" do
      post chat_messages_path(@chat), params: { message: { body: "Test message" } }
      assert_redirected_to chat_path(@chat)
    end
  end

  test "application continues to work for non-WAHA operations when WAHA is down" do
    # Simulate WAHA being down
    stub_request(:any, /http:\/\/waha:3000\/.*/)
      .to_return(status: 503, body: "Service Unavailable")

    # Test that basic Rails operations still work
    get chats_path
    assert_response :success

    get chat_path(@chat)
    assert_response :success

    # Test that database operations still work
    assert_difference "Chat.count", +1 do
      Chat.create!(wa_id: "987654321@c.us", waha_session: @waha_session)
    end
  end
end