class AccountDeletionsController < ApplicationController
  rate_limit to: 10, within: 15.minutes, only: :create, with: -> { redirect_to new_account_deletion_path, alert: t(".rate_limited") }

  def new
  end

  def create
    if Current.user.authenticate(params.expect(:password)).present?
      Current.user.delete_account
      terminate_session
      track_event "account-deleted"
      redirect_to new_session_path, notice: t(".deleted")
    else
      flash.now[:alert] = t(".wrong_password")
      render :new, status: :unprocessable_content
    end
  end
end
