require "test_helper"

class WahaWebhooksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @payload = {
      event: "messages.upsert",
      data: {
        messages: [
          {
            id: "ABCD1234",
            chatId: "123456789@c.us",
            fromMe: false,
            type: "text",
            text: { body: "Hola" },
            timestamp: 1_720_000_000
          }
        ]
      }
    }.to_json
  end

  test "creates chat and message for incoming messages.upsert" do
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