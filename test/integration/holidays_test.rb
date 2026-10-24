require "test_helper"

class HolidaysTest < ActionDispatch::IntegrationTest
  setup do
    occasions(:christmas).destroy!
  end

  test "a new group starts by picking holidays, with Christmas Day ticked" do
    sign_in_as users(:erin)
    post groups_path, params: { group: { name: "The Oaks" } }
    follow_redirect!

    assert_select "h1", text: I18n.t("groups.holidays.edit.welcome_heading", group: "The Oaks")
    assert_select "input#holiday_christmas_day[checked]"
    assert_select "input#holiday_easter_sunday[checked]", count: 0
  end

  test "a new group is only offered the holidays everyone celebrates" do
    sign_in_as users(:erin)
    post groups_path, params: { group: { name: "The Oaks" } }
    follow_redirect!

    assert_select "input#holiday_easter_sunday"
    assert_select "input#holiday_mothers_day_uk", count: 0

    get edit_group_holidays_path(Group.find_by!(name: "The Oaks"))

    assert_select "input#holiday_mothers_day_uk"
  end

  test "picking holidays for a group" do
    sign_in_as users(:alice)

    patch group_holidays_path(groups(:hollies)),
      params: { keys: [ "", "christmas_day", "mothers_day_uk" ], people: { "mothers_day_uk" => [ users(:alice).id ] } }

    assert_redirected_to groups(:hollies)
    assert groups(:hollies).celebrates?("christmas_day")
    assert_equal [ users(:alice) ], groups(:hollies).group_holidays.find_by!(key: Holiday.find("mothers_day_uk").key).recipients
  end

  test "switching every holiday off" do
    groups(:hollies).celebrate([ "christmas_day" ])
    sign_in_as users(:alice)

    patch group_holidays_path(groups(:hollies)), params: { keys: [ "" ] }

    assert_empty groups(:hollies).group_holidays.reload
  end

  test "anyone in the group can choose its holidays" do
    sign_in_as users(:bob)

    get edit_group_holidays_path(groups(:hollies))
    assert_response :success

    patch group_holidays_path(groups(:hollies)), params: { keys: [ "christmas_day" ] }
    assert groups(:hollies).celebrates?("christmas_day")
  end

  test "holidays show up in coming up, with who they're for when it isn't everyone" do
    groups(:hollies).celebrate([ "christmas_day", "fathers_day" ], people: { "fathers_day" => [ users(:bob).id ] })
    sign_in_as users(:carol)

    get group_path(groups(:hollies))

    assert_select "section[aria-labelledby=occasions-heading] li p", text: Holiday.find("christmas_day").name
    assert_select "section[aria-labelledby=occasions-heading] li p", text: /#{I18n.t("groups.coming_up.for_people", names: users(:bob).name)}/
  end

  test "the nudge for a holiday has no group in its title" do
    groups(:hollies).celebrate([ "christmas_day" ])
    travel_to Holiday.find("christmas_day").next_date - 2.weeks do
      sign_in_as users(:bob)
      get root_path

      assert_select "article[aria-label=?]", I18n.t("occasions.gifts_to_choose.label", occasion: Holiday.find("christmas_day").name) do
        assert_select "p", text: groups(:hollies).name, count: 0
      end
    end
  end
end
