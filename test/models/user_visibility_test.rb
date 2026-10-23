require "test_helper"

class UserVisibilityTest < ActiveSupport::TestCase
  test "you see yourself, the people in your groups, and your dependants" do
    visible = User.visible_to(users(:alice))

    assert_includes visible, users(:alice)
    assert_includes visible, users(:bob)
    assert_includes visible, users(:dan)
    assert_not_includes visible, users(:erin)
  end

  test "someone in two groups sees the people in both" do
    visible = User.visible_to(users(:carol))

    assert_includes visible, users(:alice)
    assert_includes visible, users(:erin)
  end

  test "guardians see their dependants even outside shared groups" do
    memberships(:dan_in_hollies).destroy!

    assert users(:dan).visible_to?(users(:alice))
  end
end
