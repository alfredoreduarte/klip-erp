require "test_helper"
require "webmock/minitest"

class ChatsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @chat = Chat.create!(wa_id: "controller_test_123456789@c.us")

    # Stub WAHA API calls
    stub_request(:get, "http://waha:3000/api/default/chats/overview")
      .to_return(status: 200, body: [].to_json, headers: { "Content-Type" => "application/json" })
    stub_request(:get, "http://waha:3000/api/default/chats/controller_test_123456789@c.us/messages?limit=100&offset=0")
      .to_return(status: 200, body: [].to_json, headers: { "Content-Type" => "application/json" })
    stub_request(:get, "http://waha:3000/api/default/profile")
      .to_return(status: 200, body: {}.to_json, headers: { "Content-Type" => "application/json" })
  end

  test "should get index" do
    get chats_url
    assert_response :success
  end

    test "should show chat" do
    get chat_url(@chat)
    assert_response :success
  end

  test "should start typing" do
    stub_request(:post, "http://waha:3000/api/startTyping")
      .to_return(status: 200, body: { success: true }.to_json)

    post typing_chat_url(@chat)
    assert_response :accepted
  end

  test "should stop typing" do
    stub_request(:post, "http://waha:3000/api/stopTyping")
      .to_return(status: 200, body: { success: true }.to_json)

    post typing_stop_chat_url(@chat)
    assert_response :accepted
  end
end