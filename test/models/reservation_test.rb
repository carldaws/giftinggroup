require "test_helper"

class ReservationTest < ActiveSupport::TestCase
  test "the list owner never sees reservations on their own list" do
    assert_not_includes Reservation.visible_to(users(:alice)), reservations(:bob_reserved_scarf)
  end

  test "the list owner sees no reservations however many groups share their list" do
    lists(:alice_christmas).shares.create!(group: groups(:ivies))
    groups(:ivies).add(users(:alice))

    assert_not_includes Reservation.visible_to(users(:alice)), reservations(:bob_reserved_scarf)
  end

  test "everyone else in the group sees reservations" do
    assert_includes Reservation.visible_to(users(:carol)), reservations(:bob_reserved_scarf)
  end

  test "people who can't see the list don't see its reservations" do
    assert_not_includes Reservation.visible_to(users(:erin)), reservations(:bob_reserved_scarf)
  end

  test "guardians see reservations on their dependant's list" do
    assert_includes Reservation.visible_to(users(:alice)), reservations(:carol_bought_lego)
  end

  test "the list owner can't reserve their own item" do
    reservation = items(:scarf).reservations.build(user: users(:alice))

    assert_not reservation.valid?
    assert reservation.errors.of_kind?(:user, :owns_the_list)
  end

  test "people who can't see the list can't reserve from it" do
    reservation = items(:scarf).reservations.build(user: users(:erin))

    assert_not reservation.valid?
    assert reservation.errors.of_kind?(:user, :cannot_see_the_list)
  end

  test "a guardian can reserve an item on their dependant's list" do
    assert items(:lego).reservations.build(user: users(:alice)).valid?
  end

  test "one reservation per person per item" do
    assert_raises(ActiveRecord::RecordNotUnique) do
      items(:scarf).reservations.create!(user: users(:bob))
    end
  end

  test "bought" do
    assert reservations(:carol_bought_lego).bought?
    assert_not reservations(:bob_reserved_scarf).bought?
  end
end
