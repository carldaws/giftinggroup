class MagicLinks::RedemptionsController < ApplicationController
  allow_unauthenticated_access
  rate_limit to: 20, within: 15.minutes, only: :create, with: -> { redirect_to new_session_path, alert: t("sessions.verifications.create.rate_limited") }

  def create
    magic_link = MagicLink.redeem_token(params.expect(:magic_link_token))

    if magic_link.present?
      sign_in_or_register magic_link.email_address
    else
      redirect_to magic_link_path(params[:magic_link_token])
    end
  end
end
