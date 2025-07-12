require "test_helper"
require "webmock/minitest"

class ChatTest < ActiveSupport::TestCase
  setup do
    # Clean up any existing data
    Message.delete_all
    Chat.delete_all
    WahaSession.delete_all

    @chat = Chat.create!(wa_id: "123456789@c.us")
    @waha_session = WahaSession.create!(name: "default")
    @chat.update!(waha_session: @waha_session)
  end

  test "sync_messages_from_waha! fetches and creates missing messages" do
    # Mock WAHA API response with both incoming and outgoing messages
    waha_response = [
      {
        "id" => "msg1",
        "fromMe" => false,
        "type" => "text",
        "body" => "Hello from sender",
        "timestamp" => 1720000000
      },
      {
        "id" => "msg2",
        "fromMe" => true,
        "type" => "text",
        "body" => "Hello from us",
        "timestamp" => 1720000001
      }
    ]

    stub_request(:get, "http://waha:3000/api/default/chats/123456789@c.us/messages?limit=100&offset=0")
      .to_return(status: 200, body: waha_response.to_json, headers: { "Content-Type" => "application/json" })

    # Initially no messages
    assert_equal 0, @chat.messages.count

    # Sync messages
    @chat.sync_messages_from_waha!

    # Should have created both messages
    assert_equal 2, @chat.messages.count

    incoming_msg = @chat.messages.incoming.first
    assert_equal "msg1", incoming_msg.wa_message_id
    assert_equal "Hello from sender", incoming_msg.body
    assert incoming_msg.incoming?

    outgoing_msg = @chat.messages.outgoing.first
    assert_equal "msg2", outgoing_msg.wa_message_id
    assert_equal "Hello from us", outgoing_msg.body
    assert outgoing_msg.outgoing?
  end

  test "sync_messages_from_waha! skips existing messages" do
    # Create an existing message
    existing_message = @chat.messages.create!(
      wa_message_id: "msg1",
      direction: :incoming,
      message_type: "text",
      body: "Existing message",
      payload: {}
    )

    # Mock WAHA API response with the same message
    waha_response = [
      {
        "id" => "msg1",
        "fromMe" => false,
        "type" => "text",
        "body" => "Hello from sender",
        "timestamp" => 1720000000
      }
    ]

    stub_request(:get, "http://waha:3000/api/default/chats/123456789@c.us/messages?limit=100&offset=0")
      .to_return(status: 200, body: waha_response.to_json, headers: { "Content-Type" => "application/json" })

    # Sync messages
    @chat.sync_messages_from_waha!

    # Should still have only 1 message (not duplicated)
    assert_equal 1, @chat.messages.count
    assert_equal existing_message.id, @chat.messages.first.id
  end

  test "sync_messages_from_waha! handles WAHA API errors gracefully" do
    stub_request(:get, "http://waha:3000/api/default/chats/123456789@c.us/messages?limit=100&offset=0")
      .to_return(status: 500, body: "Internal Server Error")

    # Should not raise an exception
    assert_nothing_raised do
      @chat.sync_messages_from_waha!
    end

    # No messages should be created
    assert_equal 0, @chat.messages.count
  end
end