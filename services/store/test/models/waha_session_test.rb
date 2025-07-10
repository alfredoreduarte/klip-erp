require "test_helper"

class WahaSessionTest < ActiveSupport::TestCase
  test "requires unique name" do
    WahaSession.create!(name: "default")
    session = WahaSession.new(name: "default")
    assert_not session.valid?, "Expected name uniqueness validation"
  end

  test "enum statuses present" do
    session = WahaSession.create!(name: "abc", status: :pending_qr)
    assert session.status_pending_qr?
    session.connected!
    assert session.status_connected?
  end
end