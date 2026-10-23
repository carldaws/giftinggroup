require "test_helper"

class SignInTest < ActionDispatch::IntegrationTest
  test "signed-out people are sent to sign in" do
    get root_path

    assert_redirected_to new_session_path
  end

  test "signing in" do
    sign_in_as users(:alice)
    assert_redirected_to root_url

    follow_redirect!
    assert_select "h1", text: I18n.t("groups.index.heading", name: users(:alice).name)
  end

  test "signing in however the email address is typed" do
    post session_path, params: { email_address: " #{users(:alice).email_address.upcase} ", password: FixturePasswords::PASSWORD }

    assert_redirected_to root_url
  end

  test "a wrong password doesn't sign you in, and keeps the email address out of the URL" do
    sign_in_as users(:alice), password: "wrong password"

    assert_response :unprocessable_content
    assert_select "#email_address[value=?]", users(:alice).email_address
    assert_select "[role=alert]", text: I18n.t("sessions.create.invalid")
    assert_not_signed_in
  end

  test "an unknown email address gets the same answer as a wrong password" do
    post session_path, params: { email_address: "nobody@example.com", password: FixturePasswords::PASSWORD }

    assert_response :unprocessable_content
    assert_select "[role=alert]", text: I18n.t("sessions.create.invalid")
  end

  test "people without an email address can't sign in" do
    post session_path, params: { email_address: users(:dan).email_address, password: "" }

    assert_response :bad_request
    assert_not_signed_in
  end

  test "signing in returns you to where you were going" do
    get root_path(from: "elsewhere")

    sign_in_as users(:alice)

    assert_redirected_to root_url(from: "elsewhere")
  end

  test "passwords can't be guessed in bulk" do
    post session_path, params: { email_address: users(:alice).email_address, password: [ "one", FixturePasswords::PASSWORD ] }

    assert_response :bad_request
    assert_not_signed_in
  end

  test "guessing passwords is rate limited by email address" do
    10.times { |n| sign_in_as users(:alice), password: "wrong", headers: { "REMOTE_ADDR" => "10.0.0.#{n}" } }

    sign_in_as users(:alice), headers: { "REMOTE_ADDR" => "10.0.0.99" }

    assert_equal I18n.t("sessions.create.rate_limited"), flash[:alert]
    assert_not_signed_in
  end

  test "signing in is rate limited by IP address" do
    20.times { |n| post session_path, params: { email_address: "person#{n}@example.com", password: "wrong" } }

    sign_in_as users(:alice)

    assert_equal I18n.t("sessions.create.rate_limited"), flash[:alert]
  end

  test "creating an account" do
    assert_difference -> { User.count } do
      post registration_path, params: { user: { name: "Fern", email_address: "fern@example.com", password: "a long enough password" } }
    end

    assert_redirected_to root_url
    assert User.exists?(email_address: "fern@example.com")
  end

  test "an account needs an email address and a long enough password" do
    assert_no_difference -> { User.count } do
      post registration_path, params: { user: { name: "Fern", email_address: "", password: "short" } }
    end

    assert_response :unprocessable_content
  end

  test "an email address can only have one account" do
    post registration_path, params: { user: { name: "Another Alice", email_address: users(:alice).email_address, password: "a long enough password" } }

    assert_response :unprocessable_content
  end

  test "creating accounts is rate limited" do
    10.times { |n| post registration_path, params: { user: { name: "Fern", email_address: "fern#{n}@example.com", password: "short" } } }

    post registration_path, params: { user: { name: "Fern", email_address: "fern@example.com", password: "a long enough password" } }

    assert_equal I18n.t("registrations.create.rate_limited"), flash[:alert]
    assert_not User.exists?(email_address: "fern@example.com")
  end

  test "signed-in people skip the sign-in and sign-up pages" do
    sign_in_as users(:alice)

    get new_session_path
    assert_redirected_to root_path

    get new_registration_path
    assert_redirected_to root_path
  end

  test "signed-in people can't sign in again or make another account" do
    sign_in_as users(:alice)

    assert_no_difference -> { Session.count } do
      sign_in_as users(:alice)
    end
    assert_redirected_to root_path

    assert_no_difference -> { User.count } do
      post registration_path, params: { user: { name: "Fern", email_address: "fern@example.com", password: "a long enough password" } }
    end
    assert_redirected_to root_path
  end

  test "signing out" do
    sign_in_as users(:alice)

    delete session_path

    assert_redirected_to new_session_path
    assert_not_signed_in
  end

  private
    def assert_not_signed_in
      get root_path
      assert_redirected_to new_session_path
    end
end
