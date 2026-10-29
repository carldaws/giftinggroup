require "test_helper"

class AnalyticsTest < ActionDispatch::IntegrationTest
  setup { Rails.configuration.x.umami = { host_url: "https://stats.example.com", website_id: "abc123" } }
  teardown { Rails.configuration.x.umami = nil }

  test "page views are sent to the stats server by route, never with names, codes or ids" do
    get join_path(groups(:hollies).join_code)

    assert_select "[data-controller=analytics][data-analytics-url-value=?]", "https://stats.example.com/api/send"
    assert_equal [ { "url" => "/join/:join_code", "tag" => "signed-out", "website" => "abc123" } ], tracked
  end

  test "signed in pages are tracked the same way" do
    sign_in_as users(:alice)
    follow_redirect!

    assert_includes tracked, { "name" => "sign-in", "url" => "/session", "data" => { "account_age" => "first week" }, "website" => "abc123" }

    get person_path(users(:bob))

    assert_equal [ { "url" => "/people/:id", "tag" => "signed-in", "website" => "abc123" } ], tracked
  end

  test "signing up counts whether it came from an invite" do
    post registration_path, params: { user: { name: "Fern", email_address: "fern@example.com", password: "a long enough password" } }
    follow_redirect!

    assert_includes tracked, { "name" => "sign-up", "url" => "/registration", "data" => { "invited" => false, "account_age" => "first week" }, "website" => "abc123" }
  end

  test "signing up from an invite says so" do
    get join_path(groups(:hollies).join_code)
    post registration_path, params: { user: { name: "Fern", email_address: "fern@example.com", password: "a long enough password" } }
    follow_redirect!

    assert_includes tracked.pluck("name", "data"), [ "sign-up", { "invited" => true, "account_age" => "first week" } ]
  end

  test "what's done is tracked once, without what was written" do
    body = "Secret Santa?"
    sign_in_as users(:alice)
    follow_redirect!
    post group_messages_path(groups(:hollies)), params: { message: { body: } }
    follow_redirect!

    assert_includes tracked, { "name" => "message-sent", "url" => "/groups/:group_id/messages", "data" => { "chat" => "group", "group_age" => "first week", "account_age" => "first week" }, "website" => "abc123" }
    assert_no_match body, css_select("[data-controller=analytics]").to_s

    get group_messages_path(groups(:hollies))

    assert_equal [ nil ], tracked.pluck("name")
  end

  test "ages are only ever sent roughly" do
    travel 2.months do
      sign_in_as users(:alice)
      follow_redirect!
    end

    assert_includes tracked.pluck("data"), { "account_age" => "first six months" }
  end

  test "a form shown again with errors is not a page view" do
    sign_in_as users(:alice)
    follow_redirect!
    post groups_path, params: { group: { name: "" } }

    assert_response :unprocessable_content
    assert_empty tracked
  end

  test "joining a group you're already in isn't tracked again" do
    sign_in_as users(:alice)
    follow_redirect!
    post joins_path, params: { join_code: groups(:hollies).join_code }
    follow_redirect!

    assert_equal [ nil ], tracked.pluck("name")
  end

  test "every event is on the public list" do
    tracked_in_code = Rails.root.glob("app/**/*.rb").flat_map { it.read.scan(/track_event "([\w-]+)"/) }.flatten

    assert_equal YAML.load_file(Rails.root.join("config/analytics.yml")).fetch("events").keys.sort, tracked_in_code.uniq.sort
  end

  test "nothing is tracked without a stats server" do
    Rails.configuration.x.umami = nil
    get root_path

    assert_select "[data-controller=analytics]", count: 0
  end

  private
    def tracked
      css_select("[data-controller=analytics]").map { JSON.parse(it["data-analytics-payload-value"]) }
    end
end
