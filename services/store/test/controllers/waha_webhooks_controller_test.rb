require "test_helper"
require "webmock/minitest"

class WahaWebhooksControllerTest < ActionDispatch::IntegrationTest
    setup do
    # Clean up any existing data
    MediaFile.delete_all
    Message.delete_all
    Chat.delete_all
    WahaSession.delete_all

    @payload = {
      event: "message",
      payload: {
        id: "ABCD1234",
        chatId: "123456789@c.us",
        fromMe: false,
        type: "text",
        body: "Hola",
        timestamp: 1_720_000_000
      },
      session: "default"
    }.to_json

    # Stub the profile picture request
    stub_request(:get, "http://waha:3000/api/contacts/profile-picture?contactId=123456789@c.us")
      .to_return(status: 200, body: { picture: "http://example.com/profile.jpg" }.to_json, headers: { "Content-Type" => "application/json" })

    # Create a default session to avoid uniqueness issues
    WahaSession.create!(name: "default", status: :connected)
  end

  test "creates chat and message for incoming message event" do
    assert_difference "Chat.count", +1 do
      assert_difference "Message.count", +1 do
        post "/waha/webhooks", params: @payload, headers: { "Content-Type" => "application/json" }
        assert_response :success
      end
    end

    chat = Chat.find_by(wa_id: "123456789@c.us")
    assert_not_nil chat

    msg = chat.messages.last
    assert_equal "ABCD1234", msg.wa_message_id
    assert_equal "Hola", msg.body
    assert msg.incoming?
  end
end