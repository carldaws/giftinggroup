require "test_helper"

class GroupTest < ActiveSupport::TestCase
  test "a new group gets a join code" do
    group = Group.create!(name: "The Oaks")

    assert_equal Group::JOIN_CODE_LENGTH, group.join_code.length
    assert_empty group.join_code.chars - Group::JOIN_CODE_ALPHABET
  end

  test "join codes are found however they're typed" do
    typed = " #{groups(:hollies).formatted_join_code.downcase} "

    assert_equal groups(:hollies), Group.find_by(join_code: typed)
  end

  test "join codes are shown in two halves" do
    assert_equal groups(:hollies).join_code, groups(:hollies).formatted_join_code.delete("-")
    assert_equal 2, groups(:hollies).formatted_join_code.split("-").size
  end

  test "regenerating the join code stops the old one working" do
    old_code = groups(:hollies).join_code
    groups(:hollies).regenerate_join_code

    assert_nil Group.find_by(join_code: old_code)
  end

  test "joining" do
    groups(:hollies).join(users(:erin))

    assert_includes groups(:hollies).members, users(:erin)
  end

  test "joining twice is harmless" do
    assert_equal memberships(:bob_in_hollies), groups(:hollies).join(users(:bob))
  end

  test "adding a dependant" do
    dependant = groups(:ivies).add_dependant({ name: "Fern" }, guardian: users(:erin))

    assert dependant.persisted?
    assert_includes groups(:ivies).members, dependant
    assert users(:erin).looks_after?(dependant)
    assert_not dependant.signs_in?
  end

  test "a dependant needs a name" do
    assert_no_difference -> { User.count } do
      assert_not groups(:ivies).add_dependant({ name: "" }, guardian: users(:erin)).persisted?
    end
  end

  test "admins" do
    assert groups(:hollies).admin?(users(:alice))
    assert_not groups(:hollies).admin?(users(:bob))
  end

  test "adding a member" do
    membership = groups(:ivies).add(users(:alice), admin: true)

    assert_includes groups(:ivies).members, users(:alice)
    assert membership.admin?
  end
end
