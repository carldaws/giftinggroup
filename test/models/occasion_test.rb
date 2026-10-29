require "test_helper"

class OccasionTest < ActiveSupport::TestCase
  test "an occasion is a birthday, a holiday or one of the group's own" do
    users(:carol).update!(birthday_month: 3, birthday_day: 12)

    assert_equal :birthday, users(:carol).birthdays.first.kind
    assert_equal :holiday, Occasion.new(holiday_key: "christmas_day").kind
    assert_equal :custom, occasions(:christmas).kind
  end

  test "a birthday makes one birthday occasion, whatever groups you're in" do
    users(:carol).update!(birthday_month: 3, birthday_day: 12)

    assert_equal [ users(:carol).next_birthday ], users(:carol).birthdays.pluck(:date)
  end

  test "everyone who shares a group with you sees your birthday, once" do
    users(:carol).update!(birthday_month: 3, birthday_day: 12)

    assert_equal 1, Occasion.visible_to(users(:alice)).where(person: users(:carol)).count
    assert_equal 1, Occasion.visible_to(users(:erin)).where(person: users(:carol)).count
  end

  test "you see your own birthday too" do
    users(:carol).update!(birthday_month: 3, birthday_day: 12)

    assert_equal 1, Occasion.visible_to(users(:carol)).where(person: users(:carol)).count
  end

  test "people who share no group with you don't see your birthday" do
    users(:alice).update!(birthday_month: 3, birthday_day: 12)

    assert_empty Occasion.visible_to(users(:erin)).where(person: users(:alice))
  end

  test "a group shows its own occasions and its members' birthdays" do
    users(:carol).update!(birthday_month: 3, birthday_day: 12)
    users(:erin).update!(birthday_month: 4, birthday_day: 1)

    in_hollies = Occasion.for_group(groups(:hollies))

    assert_includes in_hollies, occasions(:christmas)
    assert_includes in_hollies, users(:carol).birthdays.first
    assert_not_includes in_hollies, users(:erin).birthdays.first
  end

  test "everyone in the group sees its other occasions" do
    assert_includes Occasion.visible_to(users(:alice)), occasions(:christmas)
    assert_not_includes Occasion.visible_to(users(:erin)), occasions(:christmas)
  end

  test "changing your birthday moves the occasion and keeps what's reserved for it" do
    users(:alice).update!(birthday_month: 3, birthday_day: 12)
    birthday = users(:alice).birthdays.sole
    reservation = items(:socks).reservations.create!(user: users(:carol), occasion: birthday)

    users(:alice).update!(birthday_month: 4)

    assert_equal birthday, reservation.reload.occasion
    assert_equal users(:alice).next_birthday, birthday.reload.date
  end

  test "removing your birthday removes the upcoming occasion" do
    users(:carol).update!(birthday_month: 3, birthday_day: 12)
    users(:carol).update!(birthday_month: nil, birthday_day: nil)

    assert_empty users(:carol).birthdays
  end

  test "leaving a group doesn't touch your birthday" do
    users(:carol).update!(birthday_month: 3, birthday_day: 12)

    memberships(:carol_in_hollies).destroy!

    assert_equal 1, users(:carol).birthdays.count
  end

  test "birthdays roll forward to the next year once they've passed, keeping last year's" do
    travel_to Date.new(2026, 3, 1) do
      users(:carol).update!(birthday_month: 3, birthday_day: 12)
    end

    travel_to Date.new(2026, 3, 13) do
      Occasion.schedule_all

      assert_equal [ Date.new(2026, 3, 12), Date.new(2027, 3, 12) ], users(:carol).birthdays.order(:date).pluck(:date)
    end
  end

  test "rolling forward twice makes no duplicates" do
    users(:carol).update!(birthday_month: 3, birthday_day: 12)

    2.times { Occasion.schedule_all }

    assert_equal 1, users(:carol).birthdays.upcoming.count
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

  test "a birth date can't be in the future" do
    tomorrow = Date.tomorrow
    users(:carol).assign_attributes(birthday_month: tomorrow.month, birthday_day: tomorrow.day, birth_year: tomorrow.year)

    assert_not users(:carol).valid?
  end

  test "this year is a fine birth year, even after the app has been running a while" do
    travel_to Date.new(Date.current.year + 1, 12, 31) do
      users(:carol).assign_attributes(birthday_month: 1, birthday_day: 1, birth_year: Date.current.year)

      assert users(:carol).valid?
    end
  end

  test "upcoming and recent" do
    past = groups(:hollies).occasions.create!(name: "Bonfire party", date: 3.days.ago.to_date)

    assert_includes Occasion.upcoming, occasions(:christmas)
    assert_includes Occasion.recent, past
    assert_not_includes Occasion.upcoming, past
  end

  test "coming up runs from today to six months ahead" do
    travel_to Date.new(2026, 8, 31) do
      dates = [ Date.current - 1.day, Date.current, Date.current + 6.months, Date.current + 6.months + 1.day ]
      occasions = dates.map { |date| groups(:hollies).occasions.create!(name: "On #{date}", date:, for_everyone: true) }

      assert_equal occasions[1..2], Occasion.where(id: occasions).coming_up.soonest_first.to_a
    end
  end
end
