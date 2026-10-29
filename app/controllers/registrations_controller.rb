class RegistrationsController < ApplicationController
  allow_unauthenticated_access
  before_action :redirect_when_signed_in, only: %i[ new create ]
  rate_limit to: 10, within: 15.minutes, only: :create, with: -> { redirect_to new_registration_path, alert: t(".rate_limited") }

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save(context: :registration)
      invited = invited?
      sign_in @user
      track_event "sign-up", invited:
    else
      render :new, status: :unprocessable_content
    end
  end

  private
    def invited?
      return_to = session[:return_to_after_authenticating]
      return_to.present? && Rails.application.routes.recognize_path(return_to)[:controller] == "joins"
    end

    def user_params
      params.expect(user: [ :name, :email_address, :password ])
    end
end
