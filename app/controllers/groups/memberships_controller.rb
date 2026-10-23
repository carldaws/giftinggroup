class Groups::MembershipsController < ApplicationController
  include GroupScoped

  before_action :set_membership
  before_action :ensure_admin, only: :update
  before_action :ensure_removable, only: :destroy

  def update
    if @membership.update(params.expect(membership: [ :admin ]))
      redirect_to @group
    else
      redirect_to @group, alert: @membership.errors.full_messages.to_sentence
    end
  end

  def destroy
    if @membership.destroy
      redirect_after_removal
    else
      redirect_to @group, alert: @membership.errors.full_messages.to_sentence
    end
  end

  private
    def set_membership
      @membership = @group.memberships.find(params[:id])
    end

    def ensure_removable
      head :forbidden unless @membership.removable_by?(Current.user)
    end

    def redirect_after_removal
      if @membership.user == Current.user
        redirect_to root_path, notice: t(".left", group: @group.name)
      else
        redirect_to @group, notice: t(".removed", name: @membership.user.name)
      end
    end
end
