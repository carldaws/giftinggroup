require "test_helper"

class YourListsTest < ActionDispatch::IntegrationTest
  test "home links to your list, then the lists you look after, with how much is on them" do
    sign_in_as users(:alice)

    get root_path

    assert_select "#your-lists a" do |rows|
      assert_equal [ person_path(users(:alice)), person_path(users(:dan)) ], rows.map { it["href"] }
    end
    assert_select "#your-lists a[href=?]", person_path(users(:alice)), text: /#{I18n.t("groups.your_lists.things", count: 2)}/
    assert_select "#your-lists a[href=?]", person_path(users(:dan)), text: /#{I18n.t("groups.your_lists.things", count: 1)}/
  end

  test "surprise ideas, removed things and things already received aren't counted" do
    users(:dan).items.create!(name: "Dinosaur book", suggested_by: users(:carol))
    users(:alice).items.create!(name: "Old jumper").remove
    items(:socks).receive
    sign_in_as users(:alice)

    get root_path

    assert_select "#your-lists a[href=?]", person_path(users(:alice)), text: /#{I18n.t("groups.your_lists.things", count: 1)}/
    assert_select "#your-lists a[href=?]", person_path(users(:dan)), text: /#{I18n.t("groups.your_lists.things", count: 1)}/
  end

  test "only lists you look after are shown" do
    sign_in_as users(:erin)

    get root_path

    assert_select "#your-lists a", count: 1
    assert_select "#your-lists a[href=?]", person_path(users(:erin))
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
