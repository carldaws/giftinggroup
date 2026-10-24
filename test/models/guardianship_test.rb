require "test_helper"

class GuardianshipTest < ActiveSupport::TestCase
  test "people who sign in look after themselves" do
    guardianship = Guardianship.new(guardian: users(:alice), dependant: users(:bob))

    assert_not guardianship.valid?
    assert guardianship.errors.of_kind?(:dependant, :signs_in)
  end

  test "only people with their own account look after someone" do
    toddler = User.create!(name: "Toddler", memberships: [ Membership.new(group: groups(:hollies)) ])
    guardianship = Guardianship.new(guardian: toddler, dependant: users(:dan))

    assert_not guardianship.valid?
    assert guardianship.errors.of_kind?(:guardian, :does_not_sign_in)
  end

  test "people look after someone only when they're in a group together" do
    guardianship = Guardianship.new(guardian: users(:erin), dependant: users(:dan))

    assert_not guardianship.valid?
    assert guardianship.errors.of_kind?(:guardian, :not_in_a_group_together)
    assert Guardianship.new(guardian: users(:carol), dependant: users(:dan)).valid?
  end

  test "a guardian can only be removed while someone else still looks after them" do
    assert guardianships(:alice_looks_after_dan).removable?

    guardianships(:bob_looks_after_dan).destroy!

    assert_not guardianships(:alice_looks_after_dan).removable?
  end

  test "nobody is their own guardian" do
    guardianship = Guardianship.new(guardian: users(:dan), dependant: users(:dan))

    assert_not guardianship.valid?
    assert guardianship.errors.of_kind?(:dependant, :is_the_guardian)
  end
end
