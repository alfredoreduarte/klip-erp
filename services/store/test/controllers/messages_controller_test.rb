require "test_helper"
require "webmock/minitest"

class MessagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    # Clean up any existing data
    Message.delete_all
    Chat.delete_all
    WahaSession.delete_all

    # Create WAHA session first
    @waha_session = WahaSession.create!(name: "default", status: :connected)

    # Create chat with WAHA session
    @chat = Chat.create!(wa_id: "595981234567@c.us", waha_session: @waha_session)

    # Stub WAHA API calls
    stub_request(:post, "http://waha:3000/api/sendText")
      .to_return(status: 200, body: { success: true }.to_json)

    # Stub session start in case it's needed
    stub_request(:post, "http://waha:3000/api/sessions")
      .to_return(status: 200, body: {}.to_json)
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