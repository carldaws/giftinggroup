require "test_helper"

class PrivacyTest < ActionDispatch::IntegrationTest
  test "anyone can read the privacy page from the footer" do
    get new_session_path
    assert_select "footer a[href=?]", privacy_path

    get privacy_path

    assert_response :success
    assert_select "h1", text: I18n.t("privacy.show.title")
  end

  test "pages load nothing from anyone else's servers" do
    get new_session_path

    assert_select "link[href^=http], link[href^='//'], script[src^=http], script[src^='//'], img[src^=http], img[src^='//']", count: 0
  end

  test "error pages load nothing from anyone else's servers" do
    Rails.public_path.glob("*.html").each do |page|
      assert_no_match %r{(src|href)="(https?:)?//|url\((https?:)?//}, page.read
    end
  end
end
