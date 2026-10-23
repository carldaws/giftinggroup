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

  test "everyone sees a birthday coming up, the birthday person as their own" do
    users(:carol).update!(birthday_month: 3, birthday_day: 12)

    sign_in_as users(:carol)
    get group_path(groups(:hollies))
    assert_select "p", text: I18n.t("occasions.your_birthday")
    delete session_path

    sign_in_as users(:alice)
    get group_path(groups(:hollies))
    assert_select "p", text: I18n.t("occasions.birthday", name: users(:carol).name)
  end

  test "adding a birthday in your details adds a birthday occasion" do
    sign_in_as users(:carol)

    patch person_profile_path(users(:carol)), params: { user: { birthday_day: 12, birthday_month: 3, birth_year: "" } }

    assert_equal 1, users(:carol).birthdays.count
  end

  test "guardians can add a birthday for someone they look after" do
    sign_in_as users(:alice)

    patch person_profile_path(users(:dan)), params: { user: { birthday_day: 1, birthday_month: 6, birth_year: 2019 } }

    assert users(:dan).birthdays.exists?
  end

  test "other people see your birthday on your page" do
    users(:carol).update!(birthday_month: 3, birthday_day: 12)
    sign_in_as users(:alice)

    get person_path(users(:carol))

    assert_select "p.text-muted", text: /#{I18n.l(users(:carol).next_birthday, format: "%-d %B")}/
  end

  test "anyone in the group can add an occasion" do
    sign_in_as users(:carol)

    post group_occasions_path(groups(:hollies)), params: { occasion: { name: "Summer party", date: 2.months.from_now.to_date } }

    assert_redirected_to groups(:hollies)
    assert_equal users(:carol), groups(:hollies).occasions.order(:created_at).last.creator
  end

  test "adding an occasion for particular people" do
    sign_in_as users(:carol)

    post group_occasions_path(groups(:hollies)),
      params: { occasion: { name: "Anniversary", date: 2.months.from_now.to_date, member_ids: [ "", users(:alice).id, users(:bob).id ] } }

    anniversary = groups(:hollies).occasions.order(:created_at).last
    assert_equal [ users(:alice), users(:bob) ].sort_by(&:id), anniversary.recipients.sort_by(&:id)
  end

  test "the occasion form starts with everyone ticked" do
    sign_in_as users(:carol)

    get new_group_occasion_path(groups(:hollies))

    assert_select "input[type=checkbox][name='occasion[member_ids][]'][checked]", count: groups(:hollies).members.count
  end

  test "your home page reminds you who you haven't picked anything for" do
    sign_in_as users(:bob)

    get root_path

    assert_select "section[aria-label=?]", I18n.t("occasions.gifts_to_choose.label", occasion: occasions(:christmas).name) do
      assert_select "p", text: groups(:hollies).name
      assert_select "a", text: /#{users(:carol).name}/
    end
  end

  test "a group page reminds you who in that group you haven't picked anything for" do
    groups(:ivies).occasions.create!(name: "Party", date: 1.week.from_now.to_date)
    sign_in_as users(:carol)

    get group_path(groups(:hollies))

    assert_select "section[aria-labelledby=occasions-heading] [role=group][aria-label=?]", I18n.t("occasions.still_to_choose.label"), count: 1 do
      assert_select "a", text: /#{users(:bob).name}/
      assert_select "a", text: /#{users(:erin).name}/, count: 0
    end
    assert_select "section[aria-label]", count: 0
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

  test "birthday occasions can't be reached through a group, by anyone" do
    users(:carol).update!(birthday_month: 3, birthday_day: 12)
    birthday = users(:carol).birthdays.sole

    [ users(:alice), users(:carol) ].each do |user|
      sign_in_as user

      get edit_group_occasion_path(groups(:hollies), birthday)
      assert_response :not_found

      patch group_occasion_path(groups(:hollies), birthday), params: { occasion: { name: "Renamed" } }
      assert_response :not_found

      delete group_occasion_path(groups(:hollies), birthday)
      assert_response :not_found

      delete session_path
    end
  end

  test "your own birthday never appears as an occasion on other people's lists" do
    users(:carol).update!(birthday_month: 3, birthday_day: 12)
    sign_in_as users(:carol)
    post item_reservation_path(items(:socks))

    get person_path(users(:alice))

    assert_no_match I18n.t("occasions.birthday", name: users(:carol).name), response.body
  end

  test "the occasion picker lists each birthday once" do
    users(:alice).update!(birthday_month: 6, birthday_day: 1)
    groups(:ivies).join(users(:alice))
    sign_in_as users(:carol)
    post item_reservation_path(items(:socks))

    get person_path(users(:alice))

    assert_select "select[name='reservation[occasion_id]'] option", text: I18n.t("occasions.birthday", name: users(:alice).name), count: 1
  end

  test "you can say which occasion your gift is for" do
    users(:alice).update!(birthday_month: 6, birthday_day: 1)
    sign_in_as users(:carol)
    post item_reservation_path(items(:socks))
    birthday = users(:alice).birthdays.sole

    patch item_reservation_path(items(:socks)), params: { reservation: { occasion_id: birthday.id } }

    assert_equal birthday, items(:socks).reservations.find_by(user: users(:carol)).occasion
  end

  test "you can't pick an occasion that isn't for that person" do
    sign_in_as users(:carol)
    post item_reservation_path(items(:socks))
    picnic = groups(:ivies).occasions.create!(name: "Ivies picnic", date: 1.month.from_now.to_date)

    patch item_reservation_path(items(:socks)), params: { reservation: { occasion_id: picnic.id } }

    assert_equal occasions(:christmas), items(:socks).reservations.find_by(user: users(:carol)).occasion
  end

  test "once the occasion has passed, given things move out of the way for everyone else" do
    reservation = items(:scarf).reservations.sole
    reservation.update!(occasion: occasions(:christmas), bought_at: Time.current)

    travel_to occasions(:christmas).date + 1.day do
      sign_in_as users(:carol)
      get person_path(users(:alice))

      assert_select "details summary", text: I18n.t("people.show.given", count: 1)
      assert_select "details li", text: /#{I18n.t("items.item.status.they_gave_for", name: users(:bob).name, occasion: occasions(:christmas).name)}/
    end
  end

  test "after an occasion, the person is reminded to tick things off, whatever anyone got them" do
    travel_to occasions(:christmas).date + 1.day do
      sign_in_as users(:alice)
      get person_path(users(:alice))

      assert_select "p", text: I18n.t("people.show.occasion_passed", name: occasions(:christmas).name)
      assert_no_match(/gave this/, response.body)
    end
  end

  test "the person never sees that something was given, even once it has been" do
    items(:scarf).reservations.sole.update!(occasion: occasions(:christmas), bought_at: Time.current)

    travel_to occasions(:christmas).date + 1.day do
      sign_in_as users(:alice)
      get person_path(users(:alice))

      assert_select "h3", text: items(:scarf).name
      assert_select "details summary", text: /#{I18n.t("people.show.given", count: 1)}/, count: 0
      assert_no_match(/gave this/, response.body)
    end
  end

  test "a made-up occasion gets the same answer as someone else's" do
    sign_in_as users(:carol)
    post item_reservation_path(items(:socks))
    picnic = groups(:ivies).occasions.create!(name: "Ivies picnic", date: 1.month.from_now.to_date)

    patch item_reservation_path(items(:socks)), params: { reservation: { occasion_id: picnic.id } }
    someone_elses = flash[:alert]

    patch item_reservation_path(items(:socks)), params: { reservation: { occasion_id: Occasion.maximum(:id) + 1000 } }

    assert_redirected_to person_path(users(:alice))
    assert_equal someone_elses, flash[:alert]
  end

  test "a gift's occasion can't change once it's been given" do
    reservation = items(:socks).reserve_for(users(:carol))
    reservation.buy

    travel_to occasions(:christmas).date + 1.day do
      later = groups(:hollies).occasions.create!(name: "New Year", date: 1.week.from_now.to_date)

      assert_not reservation.update(occasion: later)
    end
  end

  test "you can still mark something bought after leaving the group its occasion belongs to" do
    groups(:ivies).join(users(:alice))
    reservation = items(:socks).reserve_for(users(:carol))
    assert_equal occasions(:christmas), reservation.occasion

    memberships(:carol_in_hollies).destroy!

    assert reservation.reload.buy
  end

  test "people outside a group can't see or change its occasions" do
    sign_in_as users(:erin)

    get edit_group_occasion_path(groups(:hollies), occasions(:christmas))

    assert_response :not_found
  end
end
