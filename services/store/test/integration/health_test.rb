require "test_helper"

class HealthTest < ActionDispatch::IntegrationTest
  test "up path responds with 200" do
    get "/up"
    assert_response :success
  end
end