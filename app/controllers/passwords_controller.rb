class PasswordsController < ApplicationController
  allow_unauthenticated_access
  rate_limit to: 10, within: 15.minutes, only: :update, with: -> { redirect_to new_session_path, alert: t(".rate_limited") }
  before_action :set_user
  before_action :no_store

  def edit
  end

  def update
    @user.assign_attributes(credential_params)

    if @user.save(context: :credentials)
      sign_in @user
    else
      render :edit, status: :unprocessable_content
    end
  end

  private
    def set_user
      @user = User.find_by_token_for(:sign_in_link, params[:token])
      render :expired, status: :not_found if @user.nil?
    end

    def credential_params
      if @user.signs_in?
        params.expect(user: [ :password ])
      else
        params.expect(user: [ :email_address, :password ])
      end
    end
end
