require "test_helper"

class Message::ChatTest < ActiveSupport::TestCase
  test "it starts reading from the first message you haven't read" do
    chat = memberships(:alice_in_hollies).chat_for(users(:carol))

    assert_equal messages(:about_alice), chat.first_unread
    assert_equal memberships(:alice_in_hollies).messages_about.chronologically.to_a, chat.messages.to_a
  end

  test "your own messages are yours" do
    assert messages(:about_alice).authored_by?(users(:bob))
    assert_not messages(:about_alice).authored_by?(users(:carol))
  end
end
