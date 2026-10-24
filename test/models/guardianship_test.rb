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

  test "letting someone go takes the person out of groups where nobody else looks after them" do
    ivies_only = User.create!(name: "Ivy", memberships: [ Membership.new(group: groups(:ivies)) ])
    carols = ivies_only.guardianships_as_dependant.create!(guardian: users(:carol))
    erins = ivies_only.guardianships_as_dependant.create!(guardian: users(:erin))
    groups(:hollies).join(ivies_only)

    assert carols.release

    assert_equal [ groups(:ivies) ], ivies_only.reload.groups
    assert erins.reload.persisted?
  end

  test "letting someone go cancels picks on a list you can no longer see" do
    toddler = groups(:hollies).add_dependant({ name: "Toddler" }, guardian: users(:alice))
    groups(:ivies).join(toddler)
    toddler.reload.guardianships_as_dependant.create!(guardian: users(:erin))
    reservation = toddler.items.create!(name: "Rattle").reserve_for(users(:alice))

    toddler.guardianships_as_dependant.find_by!(guardian: users(:alice)).release

    assert_not Reservation.exists?(reservation.id)
  end

  test "the last guardian can't be let go" do
    guardianships(:bob_looks_after_dan).destroy!

    assert_not guardianships(:alice_looks_after_dan).release
    assert guardianships(:alice_looks_after_dan).errors.of_kind?(:base, :last_guardian)
  end

  test "becoming a guardian doesn't stop you changing ideas you suggested before" do
    idea = users(:dan).items.create!(name: "Dinosaur book", suggested_by: users(:carol))
    users(:dan).guardianships_as_dependant.create!(guardian: users(:carol))

    assert idea.reload.update(name: "Big dinosaur book")
  end

  test "nobody is their own guardian" do
    guardianship = Guardianship.new(guardian: users(:dan), dependant: users(:dan))

    assert_not guardianship.valid?
    assert guardianship.errors.of_kind?(:dependant, :is_the_guardian)
  end
end
