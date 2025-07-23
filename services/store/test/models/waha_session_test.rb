require "test_helper"

class WahaSessionTest < ActiveSupport::TestCase
  setup do
    # Clean up any existing data in proper order
    MessageReaction.delete_all
    MediaFile.delete_all
    Message.delete_all
    Chat.delete_all
    WahaSession.delete_all
  end

  test "requires unique name" do
    WahaSession.create!(name: "default")
    session = WahaSession.new(name: "default")
    assert_not session.valid?, "Expected name uniqueness validation"
  end

  test "enum statuses present" do
    session = WahaSession.create!(name: "default", status: :pending_qr)
    assert session.pending_qr?
    session.connected!
    assert session.connected?
  end

  test "only allows default as session name" do
    # Should allow "default"
    session = WahaSession.new(name: "default")
    assert session.valid?

    # Should not allow other names
    session = WahaSession.new(name: "other")
    assert_not session.valid?
    assert_includes session.errors[:name], "is not included in the list"
  end
end