require "test_helper"

class MembershipTest < ActiveSupport::TestCase
  test "the last admin can't stop being an admin" do
    assert_not memberships(:alice_in_hollies).update(admin: false)
    assert memberships(:alice_in_hollies).errors.of_kind?(:base, :last_admin)
  end

  test "an admin can stop being an admin when there's another" do
    memberships(:bob_in_hollies).update!(admin: true)

    assert memberships(:alice_in_hollies).update(admin: false)
  end

  test "the last admin can't leave while others remain" do
    assert_not memberships(:alice_in_hollies).destroy
    assert memberships(:alice_in_hollies).errors.of_kind?(:base, :last_admin)
  end

  test "the last person leaving removes the group" do
    group = groups(:ivies)
    memberships(:erin_in_ivies).destroy!
    memberships(:carol_in_ivies).destroy!

    assert_not Group.exists?(group.id)
  end

  test "after you leave, the group no longer sees your list, but your other groups still do" do
    memberships(:carol_in_hollies).destroy!

    assert_not_includes Item.visible_to(users(:bob)), items(:books)
    assert_includes Item.visible_to(users(:erin)), items(:books)
  end

  test "deleting a group isn't blocked by its last admin" do
    assert groups(:hollies).destroy
  end

  test "dependants can't be admins" do
    assert_not memberships(:dan_in_hollies).update(admin: true)
    assert memberships(:dan_in_hollies).errors.of_kind?(:base, :dependant_admin)
  end

  test "a group's only admin can't be deleted while others remain" do
    assert_not users(:alice).destroy
    assert User.exists?(users(:alice).id)
  end

  test "deleting the last person in a group removes the group" do
    group = groups(:ivies)
    users(:erin).destroy!
    users(:carol).memberships.find_by(group:).destroy!

    assert_not Group.exists?(group.id)
  end

  test "a dependant leaves with their last guardian in the group" do
    memberships(:carol_in_hollies).update!(admin: true)

    memberships(:bob_in_hollies).destroy!
    assert_includes groups(:hollies).members, users(:dan)

    memberships(:alice_in_hollies).destroy!
    assert_not_includes groups(:hollies).members, users(:dan)
  end

  test "leaving cancels your reservations on lists you can no longer see" do
    reservation = reservations(:bob_reserved_scarf)
    memberships(:bob_in_hollies).destroy!

    assert_not Reservation.exists?(reservation.id)
  end

  test "leaving keeps reservations on lists you can still see" do
    reservation = reservations(:carol_bought_lego)
    groups(:ivies).join(users(:dan))
    memberships(:carol_in_hollies).destroy!

    assert Reservation.exists?(reservation.id)
  end

  test "people can remove themselves, their dependants, and admins can remove anyone" do
    assert memberships(:bob_in_hollies).removable_by?(users(:bob))
    assert memberships(:dan_in_hollies).removable_by?(users(:bob))
    assert memberships(:carol_in_hollies).removable_by?(users(:alice))
    assert_not memberships(:carol_in_hollies).removable_by?(users(:bob))
  end

  test "anyone in the group can make a sign-in link for another adult, but not for themselves" do
    assert memberships(:carol_in_hollies).sign_in_link_creatable_by?(users(:bob))
    assert_not memberships(:bob_in_hollies).sign_in_link_creatable_by?(users(:bob))
  end

  test "only guardians can make a set-up link for someone they look after" do
    assert memberships(:dan_in_hollies).sign_in_link_creatable_by?(users(:bob))
    assert_not memberships(:dan_in_hollies).sign_in_link_creatable_by?(users(:carol))
  end
end
