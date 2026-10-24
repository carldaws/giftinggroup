require "test_helper"

class AccountDeletionTest < ActionDispatch::IntegrationTest
  test "deleting your account needs your password" do
    sign_in_as users(:bob)

    post account_deletion_path, params: { password: "wrong" }

    assert_response :unprocessable_content
    assert User.exists?(users(:bob).id)
  end

  test "deleting your account signs you out for good" do
    bob = users(:bob)
    sign_in_as bob

    post account_deletion_path, params: { password: FixturePasswords::PASSWORD }

    assert_redirected_to new_session_path
    assert_not User.exists?(bob.id)
    get root_path
    assert_redirected_to new_session_path
  end

  test "the page names anyone whose list goes too" do
    guardianships(:bob_looks_after_dan).destroy!
    sign_in_as users(:alice)

    get new_account_deletion_path

    assert_select "li", text: /#{users(:dan).name}/
  end

  test "chats still show what someone said after they've left" do
    name = users(:bob).name
    users(:bob).delete_account
    sign_in_as users(:carol)

    get group_membership_messages_path(groups(:hollies), memberships(:alice_in_hollies))

    assert_select "li", text: /#{Regexp.escape(I18n.t("messages.message.left", name:))}/
    assert_select "li", text: /#{messages(:about_alice).body}/
  end

  test "the group sees a released item's note, but its owner doesn't" do
    name = users(:bob).name
    users(:bob).delete_account
    note = I18n.t("items.item.released", name:)

    sign_in_as users(:carol)
    get person_path(users(:alice))
    assert_select "p", text: note

    delete session_path
    sign_in_as users(:alice)
    get person_path(users(:alice))
    assert_select "p", text: note, count: 0
  end
end
