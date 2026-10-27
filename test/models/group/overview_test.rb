require "test_helper"

class Group::OverviewTest < ActiveSupport::TestCase
  test "it lists everyone in the group by name" do
    overview = Group::Overview.new(groups(:hollies), viewer: users(:bob))

    assert_equal [ users(:alice), users(:bob), users(:carol), users(:dan) ], overview.rows.map(&:person)
  end

  test "it counts the group chat messages you haven't read" do
    groups(:hollies).messages.create!(author: users(:alice), body: "Hello everyone")

    assert_equal 1, Group::Overview.new(groups(:hollies), viewer: users(:bob)).unread_count
    assert_equal 0, Group::Overview.new(groups(:hollies), viewer: users(:alice)).unread_count
  end

  test "only admins are admins" do
    assert Group::Overview.new(groups(:hollies), viewer: users(:alice)).admin?
    assert_not Group::Overview.new(groups(:hollies), viewer: users(:bob)).admin?
  end
end
