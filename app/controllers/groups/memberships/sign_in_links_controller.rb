class Groups::Memberships::SignInLinksController < ApplicationController
  include GroupScoped

  before_action :set_membership
  before_action :ensure_can_see_sign_in_link
  before_action :no_store

  def show
    @sign_in_link = edit_password_url(@membership.user.generate_token_for(:sign_in_link))
  end

  private
    def set_membership
      @membership = @group.memberships.find(params[:membership_id])
    end

    def ensure_can_see_sign_in_link
      head :forbidden unless @membership.sign_in_link_creatable_by?(Current.user)
    end
end
