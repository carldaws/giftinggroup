class RegistrationsController < ApplicationController
  allow_unauthenticated_access
  before_action :require_verified_email_address

  def new
    @user = User.new(email_address: verified_email_address)
  end

  def create
    @user = User.new(user_params.merge(email_address: verified_email_address))

    if @user.save
      sign_in @user
    else
      render :new, status: :unprocessable_content
    end
  end

  private
    def require_verified_email_address
      redirect_to new_session_path if verified_email_address.blank?
    end

    def user_params
      params.expect(user: [ :name ])
    end
end
