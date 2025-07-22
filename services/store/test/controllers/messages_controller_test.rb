require "test_helper"
require "webmock/minitest"

class MessagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @chat = Chat.create!(wa_id: "595981234567@c.us")
    stub_request(:post, "http://waha:3000/api/sendText")
      .to_return(status: 200, body: { success: true }.to_json)
  end

  test "creates outgoing message and calls WAHA" do
    assert_difference "Message.outgoing.count", +1 do
      post chat_messages_path(@chat), params: { message: { body: "Hola" } }, headers: { "Accept" => "text/vnd.turbo-stream.html" }
      assert_response :success
    end

    msg = @chat.messages.outgoing.last
    assert_equal "Hola", msg.body
  end
end