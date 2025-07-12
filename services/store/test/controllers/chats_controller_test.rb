require "test_helper"

class ChatsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @chat = Chat.create!(wa_id: "123456789@c.us")
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
    stub_request(:post, "http://localhost:4000/api/startTyping")
      .to_return(status: 200, body: { success: true }.to_json)

    post typing_chat_url(@chat)
    assert_response :accepted
  end

  test "should stop typing" do
    stub_request(:post, "http://localhost:4000/api/stopTyping")
      .to_return(status: 200, body: { success: true }.to_json)

    post typing_stop_chat_url(@chat)
    assert_response :accepted
  end
end