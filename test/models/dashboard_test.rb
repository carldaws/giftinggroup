require "test_helper"

class DashboardTest < ActiveSupport::TestCase
  test "your lists are yours and the people you look after" do
    assert_equal [ users(:alice), users(:dan) ], Dashboard.new(users(:alice)).lists.map(&:person)
  end

  test "unread messages are grouped by chat, newest first" do
    groups(:hollies).messages.create!(author: users(:alice), body: "Anyone for a group chat?")

    chats = Dashboard.new(users(:carol)).unread_chats

    assert_equal [ groups(:hollies) ], chats.map(&:group).uniq
    assert_not chats.first.about_someone?
    assert chats.drop(1).all?(&:about_someone?)
  end

  test "the shopping list splits what's still to buy from what's bought" do
    dashboard = Dashboard.new(users(:carol))
    items(:books).reserve_for(users(:carol))

    assert dashboard.shopping?
    assert_equal [ reservations(:carol_bought_lego) ], dashboard.bought
  end

  test "there's nothing to shop for until you've picked something" do
    assert_not Dashboard.new(users(:erin)).shopping?
  end

  test "a gift choice counts how many people have been chosen for" do
    choice = Occasion::Choice.new(occasion: occasions(:christmas), still_to_choose: [ users(:dan) ], everyone: [ users(:alice), users(:dan) ])

    assert_equal 1, choice.chosen_count
    assert choice.progress?
  end
end
