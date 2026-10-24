require "test_helper"

class WwwTest < ActionDispatch::IntegrationTest
  test "www sends people to the bare domain, keeping the page" do
    host! "www.giftinglists.com"

    get privacy_path

    assert_redirected_to privacy_url(host: "giftinglists.com")
  end
end
