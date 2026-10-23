require "test_helper"

class MagicLinkTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  setup do
    @email_address = users(:alice).email_address
  end

  test "a new link gets a code, a token and an expiry, and is emailed" do
    magic_link = nil
    assert_enqueued_emails(1) { magic_link = MagicLink.create!(email_address: @email_address) }

    assert_match(/\A\d{#{MagicLink::CODE_LENGTH}}\z/o, magic_link.code)
    assert magic_link.token.present?
    assert_in_delta MagicLink::LIFETIME.from_now, magic_link.expires_at, 1.second
  end

  test "email addresses must look like email addresses" do
    assert_not MagicLink.new(email_address: "alice").valid?
  end

  test "a new link replaces any earlier one for the same email address" do
    first = MagicLink.create!(email_address: @email_address)
    MagicLink.create!(email_address: @email_address)

    assert_nil MagicLink.redeem_token(first.token)
  end

  test "redeeming by token" do
    magic_link = MagicLink.create!(email_address: @email_address)

    assert_equal @email_address, MagicLink.redeem_token(magic_link.token).email_address
  end

  test "redeeming by code, however the code is typed" do
    magic_link = MagicLink.create!(email_address: @email_address)
    typed = " #{magic_link.code.first(3)} #{magic_link.code.last(3)} "

    assert_equal @email_address, MagicLink.redeem_code(email_address: @email_address, code: typed).email_address
  end

  test "a code only works with its own email address" do
    magic_link = MagicLink.create!(email_address: @email_address)

    assert_nil MagicLink.redeem_code(email_address: users(:bob).email_address, code: magic_link.code)
  end

  test "links work once" do
    magic_link = MagicLink.create!(email_address: @email_address)
    MagicLink.redeem_token(magic_link.token)

    assert_nil MagicLink.redeem_token(magic_link.token)
    assert_nil MagicLink.redeem_code(email_address: @email_address, code: magic_link.code)
  end

  test "too many wrong codes use the link up" do
    magic_link = MagicLink.create!(email_address: @email_address)
    MagicLink::MAX_FAILED_ATTEMPTS.times { MagicLink.redeem_code(email_address: @email_address, code: wrong_code_for(magic_link)) }

    assert_nil MagicLink.redeem_code(email_address: @email_address, code: magic_link.code)
  end

  test "a few wrong codes don't" do
    magic_link = MagicLink.create!(email_address: @email_address)
    (MagicLink::MAX_FAILED_ATTEMPTS - 1).times { MagicLink.redeem_code(email_address: @email_address, code: wrong_code_for(magic_link)) }

    assert MagicLink.redeem_code(email_address: @email_address, code: magic_link.code).present?
  end

  test "expired links don't work" do
    magic_link = MagicLink.create!(email_address: @email_address)

    travel MagicLink::LIFETIME + 1.second do
      assert_nil MagicLink.redeem_token(magic_link.token)
      assert_nil MagicLink.redeem_code(email_address: @email_address, code: magic_link.code)
    end
  end

  test "expired only finds links that have expired" do
    magic_link = MagicLink.create!(email_address: @email_address)

    assert_not_includes MagicLink.expired, magic_link

    travel MagicLink::LIFETIME + 1.second do
      assert_includes MagicLink.expired, magic_link
    end
  end

  private
    def wrong_code_for(magic_link)
      magic_link.code.succ.last(MagicLink::CODE_LENGTH)
    end
end
