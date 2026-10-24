require "test_helper"

class ManifestTest < ActionDispatch::IntegrationTest
  test "pages link a manifest that names the app" do
    get new_session_path

    assert_select "link[rel=manifest][href=?]", pwa_manifest_path(format: :json)

    get pwa_manifest_path(format: :json)

    assert_equal Mime[:json], response.media_type
    assert_equal I18n.t("app.name"), response.parsed_body["name"]
  end
end
