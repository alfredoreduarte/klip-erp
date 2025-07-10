require "test_helper"
require "webmock/minitest"

class WahaSessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    # Stub WAHA API endpoints used by WahaClient#start_session
    base = "http://localhost:4000"
    stub_request(:post, "#{base}/api/sessions").to_return(status: 200, body: {}.to_json)
    stub_request(:put, /#{base}\/api\/sessions\/.+/).to_return(status: 200, body: {}.to_json)
    stub_request(:post, /#{base}\/api\/sessions\/.+\/start/).to_return(status: 200, body: {}.to_json)
  end

  test "creates a new session and redirects" do
    assert_difference "WahaSession.count", +1 do
      post "/waha/sessions", params: { name: "sales1" }
      assert_redirected_to waha_sessions_path
    end

    sess = WahaSession.find_by(name: "sales1")
    assert_equal "pending_qr", sess.status
  end

  test "recreates missing WAHA session when restarting" do
    base = "http://localhost:4000"

    # Existing session persisted in Rails DB (simulating it was paired before)
    WahaSession.create!(name: "sales1", status: :connected)

    # Stub WAHA endpoints to simulate that the session does NOT exist anymore
    # WAHA will accept POST /api/sessions to create it, then allow start.
    stub_request(:post, "#{base}/api/sessions").to_return(status: 200, body: {}.to_json)
    stub_request(:post, "#{base}/api/sessions/sales1/start").to_return(status: 200, body: {}.to_json)

    assert_no_difference "WahaSession.count" do
      post "/waha/sessions", params: { name: "sales1" }
      assert_redirected_to waha_sessions_path
    end

    sess = WahaSession.find_by(name: "sales1")
    assert_equal "pending_qr", sess.status, "Session should be marked as pending_qr after restart"

    # Ensure WAHA session was (re)created and started
    assert_requested :post, "#{base}/api/sessions", times: 1
    assert_requested :post, "#{base}/api/sessions/sales1/start", times: 1
  end

  test "deletes session locally and on WAHA" do
    base = "http://localhost:4000"
    sess = WahaSession.create!(name: "sales2", status: :inactive)

    # Stub WAHA delete endpoint
    stub_request(:delete, "#{base}/api/sessions/sales2").to_return(status: 200, body: {}.to_json)

    assert_difference "WahaSession.count", -1 do
      delete "/waha/sessions/#{sess.id}"
      assert_redirected_to waha_sessions_path
    end

    assert_requested :delete, "#{base}/api/sessions/sales2", times: 1
  end
end