require "test_helper"
require "webmock/minitest"

class WahaSessionsControllerTest < ActionDispatch::IntegrationTest
    setup do
    # Clean up any existing data in proper order
    MessageReaction.delete_all
    MediaFile.delete_all
    Message.delete_all
    Chat.delete_all
    WahaSession.delete_all

    # Stub WAHA API endpoints used by WahaClient#start_session
    base = "http://waha:3000"
    stub_request(:post, "#{base}/api/sessions").to_return(status: 200, body: {}.to_json)
    stub_request(:put, /#{base}\/api\/sessions\/.+/).to_return(status: 200, body: {}.to_json)
    stub_request(:post, /#{base}\/api\/sessions\/.+\/restart/).to_return(status: 200, body: {}.to_json)
    # Stub profile endpoint to return success
    stub_request(:get, /#{base}\/api\/.+\/profile/).to_return(status: 200, body: { picture: "http://example.com/pic.jpg" }.to_json, headers: { "Content-Type" => "application/json" })
  end

  test "creates the default session and redirects" do
    assert_difference "WahaSession.count", +1 do
      post "/waha/sessions", params: { name: "default" }
      assert_redirected_to waha_sessions_path
    end

    sess = WahaSession.find_by(name: "default")
    assert_equal "pending_qr", sess.status
  end

  test "recreates missing WAHA session when restarting" do
    base = "http://waha:3000"

    # Existing session persisted in Rails DB (simulating it was paired before)
    WahaSession.create!(name: "default", status: :connected)

    # Stub WAHA endpoint to simulate that the session does NOT exist anymore.
    # WAHA will accept POST /api/sessions with start: true to recreate + autostart.
    stub_request(:post, "#{base}/api/sessions").to_return(status: 200, body: {}.to_json)
    # No /restart call is expected when the session is freshly created.

    assert_no_difference "WahaSession.count" do
      post "/waha/sessions", params: { name: "default" }
      assert_redirected_to waha_sessions_path
    end

    sess = WahaSession.find_by(name: "default")
    assert_equal "pending_qr", sess.status, "Session should be marked as pending_qr after restart"

    # Ensure WAHA session was (re)created and started
    assert_requested :post, "#{base}/api/sessions", times: 1
    assert_not_requested :post, "#{base}/api/sessions/default/restart"
  end

  test "deletes session locally and on WAHA" do
    base = "http://waha:3000"
    sess = WahaSession.create!(name: "default", status: :inactive)

    # Stub WAHA delete endpoint
    stub_request(:delete, "#{base}/api/sessions/default").to_return(status: 200, body: {}.to_json)

    assert_difference "WahaSession.count", -1 do
      delete "/waha/sessions/#{sess.id}"
      assert_redirected_to waha_sessions_path
    end

    assert_requested :delete, "#{base}/api/sessions/default", times: 1
  end
end