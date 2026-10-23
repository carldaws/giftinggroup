class Sessions::VerificationsController < ApplicationController
  allow_unauthenticated_access
  before_action :require_pending_email_address
  rate_limit to: 20, within: 15.minutes, only: :create, name: "by-ip", with: -> { reject_as_rate_limited }
  rate_limit to: 10, within: 15.minutes, only: :create, name: "by-email-address", by: -> { session[:pending_email_address] },
    with: -> { reject_as_rate_limited }

  def new
    @email_address = session[:pending_email_address]
  end

  def create
    magic_link = MagicLink.redeem_code(email_address: session[:pending_email_address], code: params.expect(:code))

    if magic_link.present?
      sign_in_or_register magic_link.email_address
    else
      redirect_to new_session_verification_path, alert: t(".invalid")
    end
  end

  private
    def require_pending_email_address
      redirect_to new_session_path if session[:pending_email_address].blank?
    end

    def reject_as_rate_limited
      redirect_to new_session_path, alert: t("sessions.verifications.create.rate_limited")
    end
end
