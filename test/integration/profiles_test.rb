require "test_helper"

class ProfilesTest < ActionDispatch::IntegrationTest
  test "changing your name and colour" do
    sign_in_as users(:alice)
    new_name = "Ally"

    patch person_profile_path(users(:alice)), params: { user: { name: new_name, avatar_tone: 2 } }

    assert_redirected_to person_path(users(:alice))
    assert_equal new_name, users(:alice).reload.name
    assert_equal User::AVATAR_TONES[2], users(:alice).avatar_tone_name
  end

  test "changing your email address needs your current password" do
    sign_in_as users(:alice)
    new_email_address = "ally@example.com"

    patch person_profile_path(users(:alice)), params: { user: { email_address: new_email_address, password_challenge: "wrong" } }
    assert_not_equal new_email_address, users(:alice).reload.email_address

    patch person_profile_path(users(:alice)), params: { user: { email_address: new_email_address, password_challenge: FixturePasswords::PASSWORD } }
    assert_equal new_email_address, users(:alice).reload.email_address
  end

  test "a failed save reopens your details" do
    sign_in_as users(:alice)

    patch person_profile_path(users(:alice)), params: { user: { name: "" } }

    assert_redirected_to person_path(users(:alice), details: "open", anchor: "details")
  end

  test "you can't remove your email address" do
    sign_in_as users(:alice)

    patch person_profile_path(users(:alice)), params: { user: { email_address: "", password_challenge: FixturePasswords::PASSWORD } }

    assert users(:alice).reload.signs_in?
  end

  test "guardians can change the name and colour of someone they look after, but not give them an email address" do
    sign_in_as users(:alice)
    new_name = "Danny"

    patch person_profile_path(users(:dan)), params: { user: { name: new_name, avatar_tone: 1, email_address: "dan@example.com" } }

    assert_equal new_name, users(:dan).reload.name
    assert_not users(:dan).signs_in?
  end

  test "nobody else can change your details" do
    sign_in_as users(:bob)

    patch person_profile_path(users(:alice)), params: { user: { name: "Not Alice" } }

    assert_response :forbidden
  end

  test "signing out from your details" do
    sign_in_as users(:alice)

    get person_path(users(:alice))
    assert_select "#details form[action=?]", session_path

    delete session_path
    assert_redirected_to new_session_path
  end
end
