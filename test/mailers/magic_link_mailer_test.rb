require "test_helper"

class MagicLinkMailerTest < ActionMailer::TestCase
  test "the sign-in email has the link and the code" do
    magic_link = MagicLink.create!(email_address: users(:alice).email_address)
    email = MagicLinkMailer.sign_in(magic_link)

    assert_equal [ magic_link.email_address ], email.to
    assert_includes email.subject, magic_link.code
    [ email.html_part, email.text_part ].each do |part|
      assert_includes part.body.to_s, magic_link.code
      assert_includes part.body.to_s, Rails.application.routes.url_helpers.magic_link_url(magic_link.token, host: "example.com")
    end
  end
end
