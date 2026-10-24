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

  test "reading the group chat doesn't mark a person's chat as read, or the other way round" do
    groups(:hollies).messages.create!(author: users(:bob), body: "Secret Santa this year?")
    sign_in_as users(:carol)

    get group_membership_messages_path(groups(:hollies), memberships(:alice_in_hollies))

    assert_equal [ nil ], Message.unread_by(users(:carol)).map(&:subject)

    get group_messages_path(groups(:hollies))

    assert_empty Message.unread_by(users(:carol)).where(group: groups(:hollies))
  end
end
