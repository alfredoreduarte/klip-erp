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
end