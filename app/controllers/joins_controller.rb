class JoinsController < ApplicationController
  allow_unauthenticated_access only: :show
  rate_limit to: 30, within: 10.minutes, only: %i[ show create ], with: -> { redirect_to root_path, alert: t("joins.rate_limited") }
  before_action :remember_invitation, only: :show, unless: :authenticated?

  def new
  end

  def show
    @group = Group.find_by(join_code: params[:join_code])
  end

  def create
    group = Group.find_by(join_code: params.expect(:join_code))

    if group.present?
      group.join(Current.user)
      redirect_to group, notice: t(".joined", group: group.name)
    else
      redirect_to new_join_path, alert: t(".not_found")
    end
  end

  private
    def remember_invitation
      session[:return_to_after_authenticating] = request.url
    end
end
