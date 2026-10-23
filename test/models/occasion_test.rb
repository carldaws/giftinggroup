require "test_helper"

class OccasionTest < ActiveSupport::TestCase
  test "a birthday makes a birthday occasion in each of your groups" do
    users(:carol).update!(birthday_month: 3, birthday_day: 12)

    assert_equal [ groups(:hollies), groups(:ivies) ].sort_by(&:id), users(:carol).birthdays.map(&:group).sort_by(&:id)
    assert users(:carol).birthdays.all? { it.date == users(:carol).next_birthday }
  end

  test "nobody sees their own birthday occasion" do
    users(:carol).update!(birthday_month: 3, birthday_day: 12)

    assert_empty Occasion.visible_to(users(:carol)).where(person: users(:carol))
    assert_not_empty Occasion.visible_to(users(:alice)).where(person: users(:carol))
  end

  test "everyone in the group sees its other occasions" do
    assert_includes Occasion.visible_to(users(:alice)), occasions(:christmas)
    assert_not_includes Occasion.visible_to(users(:erin)), occasions(:christmas)
  end

  test "changing your birthday moves the occasion, and removing it removes the occasion" do
    users(:carol).update!(birthday_month: 3, birthday_day: 12)
    users(:carol).update!(birthday_month: 4)
    assert_equal [ users(:carol).next_birthday ], users(:carol).birthdays.pluck(:date).uniq

    users(:carol).update!(birthday_month: nil, birthday_day: nil)
    assert_empty users(:carol).birthdays
  end

  test "joining a group adds your birthday to it, and leaving removes it" do
    users(:erin).update!(birthday_month: 6, birthday_day: 1)

    membership = groups(:hollies).join(users(:erin))
    assert groups(:hollies).occasions.exists?(person: users(:erin))

    membership.destroy!
    assert_not groups(:hollies).occasions.exists?(person: users(:erin))
  end

  test "birthdays roll forward to the next year once they've passed" do
    travel_to Date.new(2026, 3, 1) do
      users(:carol).update!(birthday_month: 3, birthday_day: 12)
    end

    travel_to Date.new(2026, 3, 13) do
      Occasion.schedule_all_birthdays

      assert_includes users(:carol).birthdays.upcoming.pluck(:date), Date.new(2027, 3, 12)
    end
  end

  test "a birthday is named after the person, with their age when the year is known" do
    users(:carol).update!(birthday_month: 3, birthday_day: 12)
    occasion = users(:carol).birthdays.first

    assert_equal I18n.t("occasions.birthday", name: users(:carol).name), occasion.title

    users(:carol).update!(birth_year: occasion.date.year - 40)
    assert_equal I18n.t("occasions.birthday_with_age", name: users(:carol).name, ordinal: "40th"), occasion.reload.title
  end

  test "29 February birthdays fall on 28 February in other years" do
    users(:carol).birthday_month = 2
    users(:carol).birthday_day = 29

    assert_equal Date.new(2027, 2, 28), users(:carol).next_birthday(from: Date.new(2027, 1, 1))
    assert_equal Date.new(2028, 2, 29), users(:carol).next_birthday(from: Date.new(2028, 1, 1))
  end

  test "birthdays must be real dates" do
    users(:carol).birthday_month = 2
    users(:carol).birthday_day = 30

    assert_not users(:carol).valid?
  end

  test "a birthday needs both a day and a month" do
    users(:carol).birthday_month = 2

    assert_not users(:carol).valid?
  end

  test "who can change an occasion" do
    assert occasions(:christmas).editable_by?(users(:bob))
    assert occasions(:christmas).editable_by?(users(:alice))
    assert_not occasions(:christmas).editable_by?(users(:carol))
  end

  test "birthday occasions can't be edited" do
    users(:carol).update!(birthday_month: 3, birthday_day: 12)

    assert_not users(:carol).birthdays.first.editable_by?(users(:alice))
  end

  test "upcoming and recent" do
    past = groups(:hollies).occasions.create!(name: "Bonfire party", date: 3.days.ago.to_date)

    assert_includes Occasion.upcoming, occasions(:christmas)
    assert_includes Occasion.recent, past
    assert_not_includes Occasion.upcoming, past
  end
end
