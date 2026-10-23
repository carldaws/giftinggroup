class MagicLinkMailer < ApplicationMailer
  def sign_in(magic_link)
    @magic_link = magic_link
    mail to: magic_link.email_address, subject: t(".subject", code: magic_link.code)
  end
end
