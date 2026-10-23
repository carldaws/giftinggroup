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

  test "adding a member" do
    membership = groups(:ivies).add(users(:alice), admin: true)

    assert_includes groups(:ivies).members, users(:alice)
    assert membership.admin?
  end
end
