require "test_helper"

class ChatsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @chat1 = Chat.create!(wa_id: "111@c.us", last_message_at: 1.hour.ago)
    @chat2 = Chat.create!(wa_id: "222@c.us", last_message_at: 5.minutes.ago)
  end

  test "index lists chats" do
    get chats_path
    assert_response :success
    assert_match @chat2.wa_id, @response.body
    assert_match @chat1.wa_id, @response.body
  end
end