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

  test "choosing a character, and going back to initials" do
    sign_in_as users(:alice)
    character = User::AVATAR_CHARACTERS.first

    patch person_profile_path(users(:alice)), params: { user: { avatar_character: character } }
    assert_equal character, users(:alice).reload.avatar_character

    get person_path(users(:alice))
    assert_select ".page-header img[src*=?]", character

    patch person_profile_path(users(:alice)), params: { user: { avatar_character: "" } }
    assert_nil users(:alice).reload.avatar_character
  end

  test "guardians can choose a character for someone they look after" do
    sign_in_as users(:alice)
    character = User::AVATAR_CHARACTERS.last

    patch person_profile_path(users(:dan)), params: { user: { avatar_character: character } }

    assert_equal character, users(:dan).reload.avatar_character
  end

  test "only the characters on offer can be chosen" do
    sign_in_as users(:alice)

    patch person_profile_path(users(:alice)), params: { user: { avatar_character: "dragon" } }

    assert_response :unprocessable_content
    assert_select "input[name='user[avatar_character]'][value=''][checked]"
    assert_nil users(:alice).reload.avatar_character
  end

  test "changing your email address needs your current password" do
    sign_in_as users(:alice)
    new_email_address = "ally@example.com"

    patch person_profile_path(users(:alice)), params: { user: { email_address: new_email_address, password_challenge: "wrong" } }
    assert_response :unprocessable_content
    assert_not_equal new_email_address, users(:alice).reload.email_address

    patch person_profile_path(users(:alice)), params: { user: { email_address: new_email_address, password_challenge: FixturePasswords::PASSWORD } }
    assert_equal new_email_address, users(:alice).reload.email_address
  end

  test "a failed save shows your details again with what went wrong" do
    sign_in_as users(:alice)

    patch person_profile_path(users(:alice)), params: { user: { name: "" } }

    assert_response :unprocessable_content
    assert_select "form[action=?]", person_profile_path(users(:alice))
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

  test "the details button only shows for people you look after" do
    sign_in_as users(:alice)

    get person_path(users(:dan))
    assert_select "a[href=?]", edit_person_profile_path(users(:dan))

    get person_path(users(:carol))
    assert_select "a[href=?]", edit_person_profile_path(users(:carol)), count: 0
  end

  test "guardians can open the details of someone they look after, and nobody else can" do
    sign_in_as users(:alice)
    get edit_person_profile_path(users(:dan))
    assert_response :success

    get edit_person_profile_path(users(:carol))
    assert_response :forbidden
  end

  test "nobody else can change your details" do
    sign_in_as users(:bob)

    patch person_profile_path(users(:alice)), params: { user: { name: "Not Alice" } }

    assert_response :forbidden
  end

  test "signing out from your details" do
    sign_in_as users(:alice)

    get edit_person_profile_path(users(:alice))
    assert_select "form[action=?]", session_path

    delete session_path
    assert_redirected_to new_session_path
  end

  test "people who look after someone can delete them, list and all" do
    lego = items(:lego)
    sign_in_as users(:alice)

    get edit_person_profile_path(users(:dan))
    assert_select "form[action=?] button", person_path(users(:dan)), text: I18n.t("people.profiles.edit.delete_person", name: users(:dan).name)

    delete person_path(users(:dan))

    assert_redirected_to root_path
    assert_not User.exists?(users(:dan).id)
    assert_not Item.exists?(lego.id)
  end

  test "nobody else can delete someone, and nobody with their own account can be deleted this way" do
    sign_in_as users(:carol)
    delete person_path(users(:dan))
    assert_response :forbidden

    sign_in_as users(:alice)
    [ users(:bob), users(:alice) ].each do |person|
      delete person_path(person)
      assert_response :forbidden
    end

    assert User.exists?(users(:dan).id)
    assert User.exists?(users(:bob).id)
  end
end
