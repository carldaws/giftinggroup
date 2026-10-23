require "test_helper"

class SignInTest < ActionDispatch::IntegrationTest
  test "signed-out people are sent to sign in" do
    get root_path

    assert_redirected_to new_session_path
  end

  test "signing in with the emailed code" do
    request_code_for users(:alice).email_address
    assert_redirected_to new_session_verification_path

    post session_verification_path, params: { code: code_for(users(:alice)) }
    assert_redirected_to root_url

    follow_redirect!
    assert_select "h1", text: I18n.t("groups.index.heading", name: users(:alice).name)
  end

  test "signing in with the emailed link takes a tap, so mail scanners can't use it up" do
    magic_link = MagicLink.create!(email_address: users(:alice).email_address)

    get magic_link_path(magic_link.token)
    assert_response :success
    assert MagicLink.exists?(magic_link.id)

    post magic_link_redemption_path(magic_link.token)
    assert_redirected_to root_url
  end

  test "the emailed link works on a different device from the one that asked for it" do
    magic_link = MagicLink.create!(email_address: users(:alice).email_address)

    post magic_link_redemption_path(magic_link.token)

    assert_redirected_to root_url
  end

  test "an expired link says so" do
    magic_link = MagicLink.create!(email_address: users(:alice).email_address)

    travel MagicLink::LIFETIME + 1.second do
      get magic_link_path(magic_link.token)
    end

    assert_select "h1", text: I18n.t("magic_links.show.expired_heading")
  end

  test "a used link can't be used again" do
    magic_link = MagicLink.create!(email_address: users(:alice).email_address)
    post magic_link_redemption_path(magic_link.token)
    delete session_path

    post magic_link_redemption_path(magic_link.token)

    assert_redirected_to magic_link_path(magic_link.token)
  end

  test "a wrong code doesn't sign you in" do
    request_code_for users(:alice).email_address
    post session_verification_path, params: { code: wrong_code_for(users(:alice)) }

    assert_redirected_to new_session_verification_path
    assert_equal I18n.t("sessions.verifications.create.invalid"), flash[:alert]
    assert_not_signed_in
  end

  test "codes can't be guessed in bulk" do
    request_code_for users(:alice).email_address

    post session_verification_path, params: { code: [ wrong_code_for(users(:alice)), code_for(users(:alice)) ] }

    assert_response :bad_request
    assert_not_signed_in
  end

  test "guessing codes is rate limited by email address" do
    request_code_for users(:alice).email_address
    wrong_code = wrong_code_for(users(:alice))
    10.times { |n| post session_verification_path, params: { code: wrong_code }, headers: { "REMOTE_ADDR" => "10.0.0.#{n}" } }

    post session_verification_path, params: { code: wrong_code }, headers: { "REMOTE_ADDR" => "10.0.0.99" }

    assert_equal I18n.t("sessions.verifications.create.rate_limited"), flash[:alert]
  end

  test "sign-in emails are rate limited by email address" do
    5.times { |n| post session_path, params: { magic_link: { email_address: users(:alice).email_address } }, headers: { "REMOTE_ADDR" => "10.0.1.#{n}" } }

    assert_no_enqueued_emails do
      request_code_for users(:alice).email_address
    end
    assert_equal I18n.t("sessions.create.rate_limited"), flash[:alert]
  end

  test "new people give their name once their email address is proven" do
    email_address = "fern@example.com"
    request_code_for email_address
    post session_verification_path, params: { code: MagicLink.find_by(email_address:).code }
    assert_redirected_to new_registration_path

    assert_difference -> { User.count } do
      post registration_path, params: { user: { name: "Fern" } }
    end
    assert_redirected_to root_url
    assert User.exists?(email_address:)
  end

  test "new people can register from the emailed link too" do
    magic_link = MagicLink.create!(email_address: "fern@example.com")

    post magic_link_redemption_path(magic_link.token)

    assert_redirected_to new_registration_path
  end

  test "a name is needed to register" do
    magic_link = MagicLink.create!(email_address: "fern@example.com")
    post magic_link_redemption_path(magic_link.token)

    post registration_path, params: { user: { name: "" } }

    assert_response :unprocessable_content
  end

  test "a proven email address can only be registered once" do
    magic_link = MagicLink.create!(email_address: "fern@example.com")
    post magic_link_redemption_path(magic_link.token)
    post registration_path, params: { user: { name: "Fern" } }
    delete session_path

    get new_registration_path

    assert_redirected_to new_session_path
  end

  test "a proven email address has to be registered soon after" do
    magic_link = MagicLink.create!(email_address: "fern@example.com")
    post magic_link_redemption_path(magic_link.token)

    travel Authentication::VERIFIED_EMAIL_ADDRESS_LIFETIME + 1.second do
      get new_registration_path
    end

    assert_redirected_to new_session_path
  end

  test "nobody registers without proving their email address" do
    get new_registration_path

    assert_redirected_to new_session_path
  end

  test "the code page needs an email address to check against" do
    get new_session_verification_path

    assert_redirected_to new_session_path
  end

  test "signed-in people skip the sign-in page" do
    sign_in_as users(:alice)

    get new_session_path

    assert_redirected_to root_path
  end

  test "signing out" do
    sign_in_as users(:alice)

    delete session_path
    assert_redirected_to new_session_path
    assert_not_signed_in
  end

  private
    def code_for(user)
      MagicLink.find_by(email_address: user.email_address).code
    end

    def wrong_code_for(user)
      code_for(user).succ.last(MagicLink::CODE_LENGTH)
    end

    def assert_not_signed_in
      get root_path
      assert_redirected_to new_session_path
    end
end
