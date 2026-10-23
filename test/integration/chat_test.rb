require "test_helper"

class ChatTest < ActionDispatch::IntegrationTest
  test "a person's page links to the chat about them" do
    sign_in_as users(:carol)

    get person_path(users(:alice))

    assert_select "a[href^=?]", group_membership_messages_path(groups(:hollies), memberships(:alice_in_hollies))
  end

  test "the chat page shows the chat, live" do
    sign_in_as users(:carol)

    get group_membership_messages_path(groups(:hollies), memberships(:alice_in_hollies))

    assert_select "turbo-cable-stream-source"
    assert_select "meta[name=turbo-cache-control][content=no-cache]"
    assert_select "li", text: /#{messages(:about_alice).body}/
    assert_select "form[action=?]", group_membership_messages_path(groups(:hollies), memberships(:alice_in_hollies))
  end

  test "nobody can find the chat about themselves" do
    sign_in_as users(:alice)

    get person_path(users(:alice))
    assert_select "a[href^=?]", group_membership_messages_path(groups(:hollies), memberships(:alice_in_hollies)), count: 0

    get group_membership_messages_path(groups(:hollies), memberships(:alice_in_hollies))
    assert_response :not_found
  end

  test "guardians can open the chat about someone they look after" do
    sign_in_as users(:alice)

    get group_membership_messages_path(groups(:hollies), memberships(:dan_in_hollies))

    assert_select "li", text: /#{messages(:about_dan).body}/
  end

  test "someone you share two groups with has a chat in each" do
    groups(:ivies).join(users(:bob))
    sign_in_as users(:bob)

    get person_path(users(:carol))

    assert_select "a[href^=?]", group_membership_messages_path(groups(:hollies), memberships(:carol_in_hollies)), text: /#{groups(:hollies).name}/
    assert_select "a[href^=?]", group_membership_messages_path(groups(:ivies), memberships(:carol_in_ivies)), text: /#{groups(:ivies).name}/
  end

  test "posting a message refreshes the chat for everyone watching it" do
    sign_in_as users(:bob)
    body = "Gloves are done"

    assert_turbo_stream_broadcasts memberships(:carol_in_hollies) do
      perform_enqueued_jobs do
        post group_membership_messages_path(groups(:hollies), memberships(:carol_in_hollies)), params: { message: { body: } }
      end
    end

    assert_redirected_to group_membership_messages_path(groups(:hollies), memberships(:carol_in_hollies))
    assert_equal body, memberships(:carol_in_hollies).messages_about.last.body
  end

  test "a blank message isn't posted" do
    sign_in_as users(:bob)

    assert_no_difference -> { Message.count } do
      post group_membership_messages_path(groups(:hollies), memberships(:carol_in_hollies)), params: { message: { body: " " } }
    end

    assert_response :unprocessable_content
    assert_select "[role=alert]"
  end

  test "nobody can post in the chat about themselves" do
    sign_in_as users(:alice)

    post group_membership_messages_path(groups(:hollies), memberships(:alice_in_hollies)), params: { message: { body: "Hello" } }

    assert_response :not_found
  end

  test "people outside the group can't post in its chats" do
    sign_in_as users(:erin)

    post group_membership_messages_path(groups(:hollies), memberships(:alice_in_hollies)), params: { message: { body: "Hello" } }

    assert_response :not_found
  end

  test "unread chats show on your home page until you open them" do
    sign_in_as users(:carol)

    get root_path
    assert_select "section[aria-labelledby=unread-heading] a[href^=?]", group_membership_messages_path(groups(:hollies), memberships(:alice_in_hollies))

    get group_membership_messages_path(groups(:hollies), memberships(:alice_in_hollies))
    assert_select "li#new"

    get root_path
    assert_select "section[aria-labelledby=unread-heading] a[href^=?]", group_membership_messages_path(groups(:hollies), memberships(:alice_in_hollies)), count: 0
  end
end
