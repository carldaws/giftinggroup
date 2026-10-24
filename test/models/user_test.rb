require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "what guardians add is a surprise unless the person asked for it" do
    assert users(:dan).build_item({ name: "Kite" }, by: users(:alice)).suggestion?
    assert users(:dan).build_item({ name: "Kite" }, by: users(:alice)).valid?
    assert_not users(:dan).build_item({ name: "Kite" }, by: users(:alice), asked_for: true).suggestion?
  end

  test "your own list is never a surprise, and other people's always is" do
    assert_not users(:alice).build_item({ name: "Gloves" }, by: users(:alice)).suggestion?
    assert users(:carol).build_item({ name: "Gloves" }, by: users(:alice), asked_for: true).suggestion?
  end

  test "email addresses are normalised" do
    typed = " #{users(:alice).email_address.upcase} "

    assert_equal users(:alice).email_address, User.new(email_address: typed).email_address
  end

  test "a blank email address means no email address" do
    assert_nil User.new(email_address: " ").email_address
  end

  test "people without an email address don't sign in" do
    assert users(:alice).signs_in?
    assert_not users(:dan).signs_in?
  end

  test "many people can have no email address" do
    assert User.create!(name: "Fern").persisted?
  end

  test "people who sign in need a password" do
    assert_not User.new(name: "Fern", email_address: "fern@example.com").valid?
    assert User.new(name: "Fern", email_address: "fern@example.com", password: "a long enough password").valid?
  end

  test "passwords are at least 8 characters" do
    assert_not User.new(name: "Fern", email_address: "fern@example.com", password: "short").valid?
  end

  test "passwords must fit in bcrypt's 72 bytes, however many characters that is" do
    assert_not User.new(name: "Fern", email_address: "fern@example.com", password: "é" * 40).valid?
    assert User.new(name: "Fern", email_address: "fern@example.com", password: "é" * 36).valid?
  end

  test "registering needs an email address" do
    assert_not User.new(name: "Fern").valid?(:registration)
  end

  test "email addresses are unique" do
    assert_not User.new(name: "Another Alice", email_address: users(:alice).email_address).valid?
  end

  test "everyone has an avatar colour, chosen or not" do
    assert_includes User::AVATAR_TONES, users(:bob).avatar_tone_name

    users(:bob).avatar_tone = 3
    assert_equal User::AVATAR_TONES[3], users(:bob).avatar_tone_name
  end

  test "avatar colours come from the set" do
    users(:bob).avatar_tone = User::AVATAR_TONES.size

    assert_not users(:bob).valid?
    assert_includes User::AVATAR_TONES, users(:bob).avatar_tone_name
  end

  test "avatar characters come from the set, falling back to initials" do
    users(:bob).avatar_character = "dragon"

    assert_not users(:bob).valid?
    assert_nil users(:bob).avatar_character_name
  end

  test "people look after themselves and their dependants" do
    assert users(:alice).looks_after?(users(:alice))
    assert users(:alice).looks_after?(users(:dan))
    assert_not users(:alice).looks_after?(users(:bob))
  end

  test "starting a group makes you its admin" do
    group = users(:erin).start_group(name: "The Oaks")

    assert group.persisted?
    assert group.admin?(users(:erin))
  end

  test "a group needs a name" do
    assert_not users(:erin).start_group(name: "").persisted?
  end

  test "sign-in links stop working once used" do
    token = users(:bob).generate_token_for(:sign_in_link)
    save_credentials(users(:bob), email_address: users(:bob).email_address, password: "a brand new password")

    assert_nil User.find_by_token_for(:sign_in_link, token)
  end

  test "sign-in links expire" do
    token = users(:bob).generate_token_for(:sign_in_link)

    travel 3.days + 1.second do
      assert_nil User.find_by_token_for(:sign_in_link, token)
    end
  end

  test "new credentials sign you out everywhere" do
    users(:bob).sessions.create!

    assert save_credentials(users(:bob), email_address: users(:bob).email_address, password: "a brand new password")
    assert_empty users(:bob).sessions
  end

  test "new credentials need a password" do
    assert_not save_credentials(users(:bob), email_address: users(:bob).email_address, password: "")
  end

  test "a dependant setting up their own account stops being a dependant" do
    assert save_credentials(users(:dan), email_address: "dan@example.com", password: "a brand new password")

    assert users(:dan).signs_in?
    assert_empty users(:dan).guardians
  end

  test "a dependant setting up their own account needs an email address" do
    assert_not save_credentials(users(:dan), email_address: "", password: "a brand new password")
    assert_not_empty users(:dan).reload.guardians
  end

  test "deleting someone deletes their suggestions rather than revealing them to the list owner" do
    suggestion = items(:scarf_gloves_suggestion)
    users(:bob).destroy!

    assert_not Item.exists?(suggestion.id)
  end

  test "deleting someone keeps what they wrote, under their name" do
    name = users(:bob).name

    users(:bob).destroy!

    assert messages(:about_alice).reload.author_left?
    assert_equal name, messages(:about_alice).author_name
  end

  private
    def save_credentials(user, **attributes)
      user.assign_attributes(attributes)
      user.save(context: :credentials)
    end
end
