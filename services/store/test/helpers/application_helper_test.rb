require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "waha_file_url extracts filename correctly" do
    # Test with correct WAHA URL format
    url = "http://localhost:3000/api/files/false_595982585668@c.us_977E05C3D31BC511F24D67E68C6B49FF.jpeg"
    expected = "/api/files/false_595982585668@c.us_977E05C3D31BC511F24D67E68C6B49FF.jpeg"
    assert_equal expected, waha_file_url(url)
  end

  test "waha_file_url handles URLs with session name" do
    # Test with session name in URL (incorrect format)
    url = "http://localhost:3000/api/files/default/false_595982585668@c.us_977E05C3D31BC511F24D67E68C6B49FF.jpeg"
    expected = "/api/files/false_595982585668@c.us_977E05C3D31BC511F24D67E68C6B49FF.jpeg"
    assert_equal expected, waha_file_url(url)
  end

  test "waha_file_url handles nil and blank URLs" do
    assert_nil waha_file_url(nil)
    assert_nil waha_file_url("")
    assert_nil waha_file_url("   ")
  end

  test "waha_file_url handles relative URLs" do
    url = "/api/files/false_595982585668@c.us_977E05C3D31BC511F24D67E68C6B49FF.jpeg"
    expected = "/api/files/false_595982585668@c.us_977E05C3D31BC511F24D67E68C6B49FF.jpeg"
    assert_equal expected, waha_file_url(url)
  end
end