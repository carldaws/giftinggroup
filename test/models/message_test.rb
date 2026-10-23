require "test_helper"

class MessageTest < ActiveSupport::TestCase
  test "nobody sees the chat about themselves" do
    assert_not_includes Message.visible_to(users(:alice)), messages(:about_alice)
  end

  test "everyone else in the group sees the chat about a member" do
    assert_includes Message.visible_to(users(:carol)), messages(:about_alice)
  end

  test "guardians see the chat about their dependant" do
    assert_includes Message.visible_to(users(:alice)), messages(:about_dan)
  end

  test "people outside the group don't see its chats" do
    assert_not_includes Message.visible_to(users(:erin)), messages(:about_alice)
  end

  test "a member of two groups sees chats in both" do
    visible = Message.visible_to(users(:carol))

    assert_includes visible, messages(:about_alice)
    assert_includes visible, messages(:about_erin)
  end

  test "nobody can post in the chat about themselves" do
    message = memberships(:alice_in_hollies).messages_about.build(author: users(:alice), body: "Hello")

    assert_not message.valid?
    assert message.errors.of_kind?(:author, :is_being_discussed)
  end

  test "only group members can post" do
    message = memberships(:alice_in_hollies).messages_about.build(author: users(:erin), body: "Hello")

    assert_not message.valid?
    assert message.errors.of_kind?(:author, :not_in_the_group)
  end
end
