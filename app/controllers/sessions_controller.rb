class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  before_action :redirect_when_signed_in, only: %i[ new create ]
  rate_limit to: 20, within: 3.minutes, only: :create, name: "by-ip", with: -> { reject_as_rate_limited }
  rate_limit to: 10, within: 1.hour, only: :create, name: "by-email-address", by: -> { attempted_email_address },
    with: -> { reject_as_rate_limited }

  def new
  end

  def create
    user = User.authenticate_by(email_address: attempted_email_address, password: params.expect(:password))

    if user.present?
      sign_in user
      track_event "sign-in"
    else
      flash.now[:alert] = t(".invalid")
      render :new, status: :unprocessable_content
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path, status: :see_other
  end

  private
    def attempted_email_address
      User.normalize_value_for(:email_address, params.expect(:email_address))
    end

    def reject_as_rate_limited
      redirect_to new_session_path, alert: t(".rate_limited")
    end
end
