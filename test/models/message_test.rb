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

class MessageUnreadTest < ActiveSupport::TestCase
  test "messages count as unread until you open the chat" do
    assert_includes Message.unread_by(users(:carol)), messages(:about_alice)

    memberships(:alice_in_hollies).mark_read_by(users(:carol))

    assert_not_includes Message.unread_by(users(:carol)), messages(:about_alice)
  end

  test "new messages after you've read the chat are unread" do
    memberships(:alice_in_hollies).mark_read_by(users(:carol))

    travel 1.minute do
      newer = memberships(:alice_in_hollies).messages_about.create!(author: users(:bob), body: "Gloves too?")

      assert_includes Message.unread_by(users(:carol)), newer
    end
  end

  test "your own messages are never unread" do
    assert_not_includes Message.unread_by(users(:bob)), messages(:about_alice)
  end

  test "nobody has unread messages about themselves" do
    assert_not_includes Message.unread_by(users(:alice)), messages(:about_alice)
  end

  test "line breaks are stored the way the browser counts them" do
    lines = %w[ Scarf Gloves ]

    message = memberships(:alice_in_hollies).messages_about.create!(author: users(:bob), body: lines.join("\r\n"))

    assert_equal lines.join("\n"), message.body
  end
end
