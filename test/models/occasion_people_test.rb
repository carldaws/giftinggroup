require "test_helper"

class OccasionPeopleTest < ActiveSupport::TestCase
  test "an occasion for particular people only applies to them" do
    anniversary = groups(:hollies).occasions.new(name: "Anniversary", date: 1.month.from_now.to_date, member_ids: [ users(:alice).id, users(:bob).id ])
    assert anniversary.save

    assert_not anniversary.for_everyone?
    assert_includes Occasion.applying_to(users(:alice)), anniversary
    assert_not_includes Occasion.applying_to(users(:carol)), anniversary
  end

  test "ticking everyone makes it for everyone, including people who join later" do
    party = groups(:hollies).occasions.new(name: "Party", date: 1.month.from_now.to_date, member_ids: groups(:hollies).member_ids)
    assert party.save
    assert party.for_everyone?

    groups(:hollies).join(users(:erin))

    assert_includes Occasion.applying_to(users(:erin)), party
  end

  test "an occasion has to be for someone" do
    party = groups(:hollies).occasions.new(name: "Party", date: 1.month.from_now.to_date, member_ids: [ "" ])

    assert_not party.save
    assert party.errors.of_kind?(:base, :for_no_one)
  end

  test "only people in the group can be chosen" do
    party = groups(:hollies).occasions.new(name: "Party", date: 1.month.from_now.to_date, member_ids: [ users(:alice).id, users(:erin).id ])
    assert party.save

    assert_equal [ users(:alice) ], party.recipients
  end

  test "a failed change leaves who it's for alone" do
    anniversary = groups(:hollies).occasions.new(name: "Anniversary", date: 1.month.from_now.to_date, member_ids: [ users(:alice).id, users(:bob).id ])
    assert anniversary.save

    assert_not anniversary.update(name: "", member_ids: [ users(:carol).id ])

    assert_equal [ users(:alice), users(:bob) ].sort_by(&:id), anniversary.reload.recipients.sort_by(&:id)
  end

  test "reserving for someone doesn't pick an occasion that isn't for them" do
    anniversary = groups(:hollies).occasions.new(name: "Anniversary", date: 1.week.from_now.to_date, member_ids: [ users(:bob).id ])
    assert anniversary.save

    assert_equal occasions(:christmas), items(:books).reserve_for(users(:bob)).occasion
  end

  test "you're reminded about people you haven't picked anything for, never yourself" do
    occasion, people = users(:bob).gifts_to_choose.first

    assert_equal occasions(:christmas), occasion
    assert_equal [ users(:alice), users(:carol), users(:dan) ].sort_by(&:id), people.sort_by(&:id)
  end

  test "picking something for someone for the occasion takes them off the reminder" do
    items(:books).reservations.create!(user: users(:bob), occasion: occasions(:christmas))

    _, people = users(:bob).gifts_to_choose.first

    assert_not_includes people, users(:carol)
  end

  test "a pick that's taken off their list puts them back on the reminder, unless it's bought" do
    reservation = items(:books).reservations.create!(user: users(:bob), occasion: occasions(:christmas))
    items(:books).remove

    _, people = users(:bob).gifts_to_choose.first
    assert_includes people, users(:carol)

    reservation.buy
    _, people = users(:bob).gifts_to_choose.first
    assert_not_includes people, users(:carol)
  end

  test "a birthday only reminds you about the birthday person" do
    users(:dan).update!(birthday_month: 1.week.from_now.month, birthday_day: 1.week.from_now.day)

    occasion, people = users(:bob).gifts_to_choose.first

    assert occasion.birthday?
    assert_equal [ users(:dan) ], people
  end

  test "once everyone's covered, the reminder moves on" do
    [ items(:socks), items(:books) ].each { it.reservations.create!(user: users(:bob), occasion: occasions(:christmas)) }
    users(:dan).items.create!(name: "Kite").reservations.create!(user: users(:bob), occasion: occasions(:christmas))

    assert_empty users(:bob).gifts_to_choose
  end

  test "the next occasion always reminds you, however far away" do
    occasions(:christmas).update!(date: 10.weeks.from_now.to_date)

    occasion, _ = users(:bob).gifts_to_choose.first

    assert_equal occasions(:christmas), occasion
  end

  test "later occasions only remind you within six weeks" do
    [ items(:socks), items(:books) ].each { it.reservations.create!(user: users(:bob), occasion: occasions(:christmas)) }
    users(:dan).items.create!(name: "Kite").reservations.create!(user: users(:bob), occasion: occasions(:christmas))

    far = groups(:hollies).occasions.create!(name: "Summer party", date: 10.weeks.from_now.to_date)
    assert_empty users(:bob).gifts_to_choose

    far.update!(date: 5.weeks.from_now.to_date)
    occasion, _ = users(:bob).gifts_to_choose.first
    assert_equal far, occasion
  end

  test "each occasion gets its own reminder" do
    groups(:ivies).join(users(:bob))
    ivies_christmas = groups(:ivies).occasions.create!(name: "Christmas", date: occasions(:christmas).date)

    reminded = users(:bob).gifts_to_choose.map(&:first)

    assert_includes reminded, occasions(:christmas)
    assert_includes reminded, ivies_christmas
  end

  test "your own birthday doesn't count as the next occasion" do
    users(:bob).update!(birthday_month: 1.week.from_now.month, birthday_day: 1.week.from_now.day)
    occasions(:christmas).update!(date: 10.weeks.from_now.to_date)

    occasion, _ = users(:bob).gifts_to_choose.first

    assert_equal occasions(:christmas), occasion
  end

  test "a group's reminders only cover its own occasions" do
    ivies_party = groups(:ivies).occasions.create!(name: "Party", date: 1.week.from_now.to_date)

    assert_equal [ ivies_party ], users(:carol).gifts_to_choose(in_group: groups(:ivies)).map(&:first)
    assert_not_includes users(:carol).gifts_to_choose(in_group: groups(:hollies)).map(&:first), ivies_party
  end

  test "a group's reminder for a holiday only names people in that group" do
    groups(:hollies).celebrate([ "christmas_day" ])
    groups(:ivies).celebrate([ "christmas_day" ])

    travel_to Holiday.find("christmas_day").next_date - 2.weeks do
      everywhere = users(:carol).gifts_to_choose.find { |occasion, _| occasion.holiday? }.second
      in_ivies = users(:carol).gifts_to_choose(in_group: groups(:ivies)).find { |occasion, _| occasion.holiday? }.second

      assert_includes everywhere, users(:alice)
      assert_equal [ users(:erin) ], in_ivies
    end
  end
end
