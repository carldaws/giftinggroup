require "test_helper"

class GroupChatTest < ActionDispatch::IntegrationTest
  test "the group page links to a chat for everyone, live" do
    sign_in_as users(:alice)

    get group_path(groups(:hollies))
    assert_select "a[href^=?]", group_messages_path(groups(:hollies))

    get group_messages_path(groups(:hollies))
    assert_select "turbo-cable-stream-source"
    assert_match I18n.t("groups.messages.index.for_everyone"), response.body
  end

  test "everyone in the group can talk there, including the people being talked about elsewhere" do
    sign_in_as users(:alice)

    post group_messages_path(groups(:hollies)), params: { message: { body: "Secret Santa this year?" } }

    assert_redirected_to group_messages_path(groups(:hollies))
    message = groups(:hollies).messages.for_everyone.last
    assert_equal users(:alice), message.author
    assert_includes Message.visible_to(users(:bob)), message
  end

  test "people outside the group can't see or join its chat" do
    groups(:hollies).messages.create!(author: users(:alice), body: "Secret Santa this year?")
    sign_in_as users(:erin)

    get group_messages_path(groups(:hollies))
    assert_response :not_found

    post group_messages_path(groups(:hollies)), params: { message: { body: "Hello" } }
    assert_response :not_found
    assert_empty Message.visible_to(users(:erin)).where(group: groups(:hollies))
  end

  test "new messages for everyone show on the home page until they're read" do
    groups(:hollies).messages.create!(author: users(:bob), body: "Secret Santa this year?")
    sign_in_as users(:alice)

    get root_path
    assert_select "section[aria-labelledby=unread-heading] a[href^=?]", group_messages_path(groups(:hollies)),
      text: /#{I18n.t("messages.unread.everyone", group: groups(:hollies).name)}/

    get group_messages_path(groups(:hollies))
    get root_path
    assert_select "section[aria-labelledby=unread-heading] a[href^=?]", group_messages_path(groups(:hollies)), count: 0
  end

  test "reading the group chat leaves the chats about people unread" do
    groups(:hollies).messages.create!(author: users(:bob), body: "Secret Santa this year?")
    sign_in_as users(:carol)

    get group_messages_path(groups(:hollies))

    assert_equal [ messages(:about_alice) ], Message.unread_by(users(:carol)).to_a
  end

  test "reading a chat about someone leaves the group chat unread" do
    message = groups(:hollies).messages.create!(author: users(:bob), body: "Secret Santa this year?")
    sign_in_as users(:carol)

    get group_membership_messages_path(groups(:hollies), memberships(:alice_in_hollies))

    assert_equal [ message ], Message.unread_by(users(:carol)).to_a
  end

  test "the group chat never shows the chats about people" do
    sign_in_as users(:alice)

    get group_messages_path(groups(:hollies))
    assert_no_match messages(:about_alice).body, response.body
    assert_no_match messages(:about_dan).body, response.body

    get group_path(groups(:hollies))
    assert_select "a[aria-label=?]", I18n.t("groups.show.chat", count: 0)
  end

  test "the group page only counts that group's new messages for everyone" do
    groups(:ivies).messages.create!(author: users(:erin), body: "Tent or hammock?")
    groups(:hollies).messages.create!(author: users(:bob), body: "Secret Santa this year?")
    sign_in_as users(:carol)

    get group_path(groups(:hollies))

    assert_select "a[aria-label=?]", I18n.t("groups.show.chat", count: 1)
  end

  test "people who don't sign in aren't counted among the people in the group chat" do
    assert_not_includes groups(:hollies).chat_readers, users(:dan)
    assert_includes groups(:hollies).chat_readers, users(:alice)
  end

  test "messages for everyone refresh the group chat live" do
    assert_turbo_stream_broadcasts [ groups(:hollies), :chat ] do
      perform_enqueued_jobs { groups(:hollies).messages.create!(author: users(:bob), body: "Secret Santa this year?") }
    end
  end

  test "messages about someone never reach the group chat's stream" do
    assert_no_turbo_stream_broadcasts [ groups(:hollies), :chat ] do
      perform_enqueued_jobs { memberships(:alice_in_hollies).messages_about.create!(author: users(:bob), body: "Scarf sorted") }
    end
    assert_turbo_stream_broadcasts memberships(:alice_in_hollies) do
      perform_enqueued_jobs { memberships(:alice_in_hollies).messages_about.create!(author: users(:bob), body: "Gloves too") }
    end
  end

  test "a group with a chat can still be deleted, along with who has read it" do
    groups(:ivies).messages.create!(author: users(:erin), body: "Tent or hammock?")
    groups(:ivies).mark_read_by(users(:carol))

    groups(:ivies).destroy!

    assert_empty Message.where(group_id: groups(:ivies).id)
    assert_empty Reading.where(group_id: groups(:ivies).id)
  end

  test "deleting an account keeps what someone said for everyone" do
    message = groups(:ivies).messages.create!(author: users(:erin), body: "Tent or hammock?")

    users(:erin).delete_account

    assert_equal users(:erin).name, message.reload.author_name
  end
end
