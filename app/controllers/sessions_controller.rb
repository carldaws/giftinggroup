class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  before_action :redirect_when_signed_in, only: :new
  rate_limit to: 10, within: 3.minutes, only: :create, name: "by-ip", with: -> { reject_as_rate_limited }
  rate_limit to: 5, within: 15.minutes, only: :create, name: "by-email-address", by: -> { requested_email_address },
    with: -> { reject_as_rate_limited }

  def new
    @magic_link = MagicLink.new
  end

  def create
    @magic_link = MagicLink.new(magic_link_params)

    if @magic_link.save
      session[:pending_email_address] = @magic_link.email_address
      redirect_to new_session_verification_path
    else
      render :new, status: :unprocessable_content
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path, status: :see_other
  end

  private
    def magic_link_params
      params.expect(magic_link: [ :email_address ])
    end

    def requested_email_address
      MagicLink.normalize_value_for(:email_address, magic_link_params[:email_address].to_s)
    end

    def redirect_when_signed_in
      redirect_to root_path if authenticated?
    end

    def reject_as_rate_limited
      redirect_to new_session_path, alert: t("sessions.create.rate_limited")
    end
end
