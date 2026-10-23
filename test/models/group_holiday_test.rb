require "test_helper"

class GroupHolidayTest < ActiveSupport::TestCase
  setup do
    occasions(:christmas).destroy!
  end

  def christmas
    Holiday.find("christmas_day")
  end

  test "celebrating a holiday makes its next occasion" do
    groups(:hollies).celebrate([ "christmas_day" ])

    occasion = christmas.occasions.sole
    assert_equal Holiday.find("christmas_day").next_date, occasion.date
  end

  test "two groups celebrating the same holiday share one occasion" do
    groups(:hollies).celebrate([ "christmas_day" ])
    groups(:ivies).celebrate([ "christmas_day" ])

    assert_equal 1, christmas.occasions.count
  end

  test "only people in a celebrating group see the holiday" do
    groups(:hollies).celebrate([ "christmas_day" ])

    assert Occasion.visible_to(users(:alice)).exists?(holiday_key: "christmas_day")
    assert_not Occasion.visible_to(users(:erin)).exists?(holiday_key: "christmas_day")
  end

  test "holidays for everyone apply to everyone in the group, including people who join later" do
    groups(:hollies).celebrate([ "christmas_day" ])
    groups(:hollies).join(users(:erin))

    assert Occasion.applying_to(users(:erin)).exists?(holiday_key: "christmas_day")
  end

  test "holidays for particular people only apply to them" do
    groups(:hollies).celebrate([ "mothers_day_uk" ], people: { "mothers_day_uk" => [ users(:alice).id.to_s ] })

    assert Occasion.applying_to(users(:alice)).exists?(holiday_key: "mothers_day_uk")
    assert_not Occasion.applying_to(users(:carol)).exists?(holiday_key: "mothers_day_uk")
  end

  test "a holiday only counts for gifts between people who share a group that celebrates it" do
    groups(:hollies).celebrate([ "christmas_day" ])

    assert Occasion.for_gifts_to(users(:carol), from: users(:alice)).exists?(holiday_key: "christmas_day")
    assert_not Occasion.for_gifts_to(users(:carol), from: users(:erin)).exists?(holiday_key: "christmas_day")
  end

  test "one present for someone covers the holiday in every group" do
    groups(:hollies).celebrate([ "christmas_day" ])
    groups(:ivies).celebrate([ "christmas_day" ])
    groups(:ivies).join(users(:bob))
    christmas_2026 = christmas.occasions.sole

    items(:books).reservations.create!(user: users(:bob), occasion: christmas_2026)

    christmas_reminder = users(:bob).gifts_to_choose.find { |occasion, _| occasion == christmas_2026 }
    assert_not_includes christmas_reminder.second, users(:carol)
  end

  test "the holiday reminder covers everyone across your celebrating groups, once" do
    groups(:hollies).celebrate([ "christmas_day" ])
    groups(:ivies).celebrate([ "christmas_day" ])
    groups(:ivies).join(users(:bob))
    christmas_2026 = christmas.occasions.sole

    reminders = users(:bob).gifts_to_choose.select { |occasion, _| occasion == christmas_2026 }

    assert_equal 1, reminders.size
    assert_includes reminders.first.second, users(:erin)
    assert_equal 1, reminders.first.second.count(users(:carol))
  end

  test "switching a holiday off" do
    groups(:hollies).celebrate([ "christmas_day", "easter_sunday" ])
    groups(:hollies).celebrate([ "easter_sunday" ])

    assert_not groups(:hollies).reload.celebrates?("christmas_day")
    assert groups(:hollies).celebrates?("easter_sunday")
  end

  test "only real holidays can be celebrated" do
    groups(:hollies).celebrate([ "talk_like_a_pirate_day" ])

    assert_empty groups(:hollies).group_holidays
  end

  test "only people in the group can be chosen for a holiday" do
    groups(:hollies).celebrate([ "fathers_day" ], people: { "fathers_day" => [ users(:bob).id, users(:erin).id ] })

    assert_equal [ users(:bob) ], groups(:hollies).group_holidays.sole.recipients
  end

  test "holidays roll forward with the daily job" do
    travel_to Date.new(2026, 12, 1) do
      groups(:hollies).celebrate([ "christmas_day" ])
    end

    travel_to Date.new(2026, 12, 26) do
      Occasion.schedule_all

      assert_equal [ Date.new(2026, 12, 25), Date.new(2027, 12, 25) ], christmas.occasions.order(:date).pluck(:date)
    end
  end

  test "holidays can't be edited like a group's own occasions" do
    groups(:hollies).celebrate([ "christmas_day" ])

    assert_not_includes groups(:hollies).occasions, christmas.occasions.sole
  end
end
