require "test_helper"

class Membership::RowTest < ActiveSupport::TestCase
  test "admins can make other adults admins, but not dependants" do
    assert Membership::Row.new(memberships(:bob_in_hollies), viewer: users(:alice), viewer_admin: true).admin_toggle?
    assert_not Membership::Row.new(memberships(:dan_in_hollies), viewer: users(:alice), viewer_admin: true).admin_toggle?
  end

  test "your own row is yours, and you can leave" do
    row = Membership::Row.new(memberships(:bob_in_hollies), viewer: users(:bob), viewer_admin: false)

    assert row.yours?
    assert row.removable?
    assert row.menu?
  end

  test "someone else's row has no menu unless you can do something with it" do
    assert Membership::Row.new(memberships(:carol_in_hollies), viewer: users(:bob), viewer_admin: false).menu?
    assert_not Membership::Row.new(memberships(:dan_in_hollies), viewer: users(:carol), viewer_admin: false).menu?
  end

  test "the divider only separates removing from the options above it" do
    assert Membership::Row.new(memberships(:bob_in_hollies), viewer: users(:alice), viewer_admin: true).divider?
    assert_not Membership::Row.new(memberships(:bob_in_hollies), viewer: users(:bob), viewer_admin: false).divider?
  end
end
