require "test_helper"

class YourListsTest < ActionDispatch::IntegrationTest
  test "home links to your list and the lists you look after, with how much is on them" do
    sign_in_as users(:alice)

    get root_path

    assert_select "#your-lists a[href=?]", person_path(users(:alice)), text: /#{I18n.t("groups.your_lists.things", count: 2)}/
    assert_select "#your-lists a[href=?]", person_path(users(:dan)), text: /#{I18n.t("groups.your_lists.theirs", name: users(:dan).name)}/
  end

  test "surprise ideas and things already received aren't counted" do
    users(:alice).items.create!(name: "Secret idea", suggested_by: users(:carol))
    items(:socks).receive
    sign_in_as users(:alice)

    get root_path

    assert_select "#your-lists a[href=?]", person_path(users(:alice)), text: /#{I18n.t("groups.your_lists.things", count: 1)}/
  end

  test "an empty list gets a gentle nudge" do
    sign_in_as users(:bob)

    get root_path

    assert_select "#your-lists a[href=?]", person_path(users(:bob)), text: /#{I18n.t("groups.your_lists.empty_yours")}/
  end

  test "an empty list you look after gets a nudge too" do
    users(:dan).items.destroy_all
    sign_in_as users(:alice)

    get root_path

    assert_select "#your-lists a[href=?]", person_path(users(:dan)), text: /#{I18n.t("groups.your_lists.empty_theirs", name: users(:dan).name)}/
  end
end
