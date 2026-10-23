require "test_helper"

class OccasionsTest < ActionDispatch::IntegrationTest
  test "the group page shows what's coming up" do
    sign_in_as users(:carol)

    get group_path(groups(:hollies))

    assert_select "section[aria-labelledby=occasions-heading] li p", text: occasions(:christmas).name
  end

  test "occasions you can change have an edit button" do
    sign_in_as users(:bob)

    get group_path(groups(:hollies))

    assert_select "a[href=?]", edit_group_occasion_path(groups(:hollies), occasions(:christmas)), text: I18n.t("groups.coming_up.edit")
  end

  test "your own birthday never shows up for you, but does for everyone else" do
    users(:carol).update!(birthday_month: 3, birthday_day: 12)
    birthday = I18n.t("occasions.birthday", name: users(:carol).name)

    sign_in_as users(:carol)
    get group_path(groups(:hollies))
    assert_no_match birthday, response.body
    delete session_path

    sign_in_as users(:alice)
    get group_path(groups(:hollies))
    assert_select "p", text: birthday
  end

  test "adding a birthday in your details adds it to your groups" do
    sign_in_as users(:carol)

    patch person_profile_path(users(:carol)), params: { user: { birthday_day: 12, birthday_month: 3, birth_year: "" } }

    assert_equal 2, users(:carol).birthdays.count
  end

  test "guardians can add a birthday for someone they look after" do
    sign_in_as users(:alice)

    patch person_profile_path(users(:dan)), params: { user: { birthday_day: 1, birthday_month: 6, birth_year: 2019 } }

    assert groups(:hollies).occasions.exists?(person: users(:dan))
  end

  test "other people see your birthday on your page" do
    users(:carol).update!(birthday_month: 3, birthday_day: 12)
    sign_in_as users(:alice)

    get person_path(users(:carol))

    assert_select "h1 ~ p", text: /#{I18n.l(users(:carol).next_birthday, format: "%-d %B")}/
  end

  test "anyone in the group can add an occasion" do
    sign_in_as users(:carol)

    post group_occasions_path(groups(:hollies)), params: { occasion: { name: "Summer party", date: 2.months.from_now.to_date } }

    assert_redirected_to groups(:hollies)
    assert_equal users(:carol), groups(:hollies).occasions.order(:created_at).last.creator
  end

  test "an occasion needs a name and a date" do
    sign_in_as users(:carol)

    post group_occasions_path(groups(:hollies)), params: { occasion: { name: "", date: "" } }

    assert_response :unprocessable_content
  end

  test "whoever added an occasion, or an admin, can change or remove it" do
    sign_in_as users(:alice)

    patch group_occasion_path(groups(:hollies), occasions(:christmas)), params: { occasion: { name: "Christmas Day" } }
    assert_redirected_to groups(:hollies)

    delete group_occasion_path(groups(:hollies), occasions(:christmas))
    assert_not Occasion.exists?(occasions(:christmas).id)
  end

  test "other members can't change someone else's occasion" do
    sign_in_as users(:carol)

    patch group_occasion_path(groups(:hollies), occasions(:christmas)), params: { occasion: { name: "Carol's Christmas" } }

    assert_response :forbidden
  end

  test "birthday occasions can't be changed by hand" do
    users(:carol).update!(birthday_month: 3, birthday_day: 12)
    sign_in_as users(:alice)

    get edit_group_occasion_path(groups(:hollies), users(:carol).birthdays.find_by(group: groups(:hollies)))

    assert_response :forbidden
  end

  test "you can't reach your own birthday occasion at all" do
    users(:carol).update!(birthday_month: 3, birthday_day: 12)
    sign_in_as users(:carol)

    get edit_group_occasion_path(groups(:hollies), users(:carol).birthdays.find_by(group: groups(:hollies)))

    assert_response :not_found
  end

  test "people outside a group can't see or change its occasions" do
    sign_in_as users(:erin)

    get edit_group_occasion_path(groups(:hollies), occasions(:christmas))

    assert_response :not_found
  end
end
