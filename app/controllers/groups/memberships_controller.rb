class Groups::MembershipsController < ApplicationController
  include GroupScoped

  before_action :set_membership, except: :create
  before_action :ensure_admin, only: :update
  before_action :ensure_removable, only: :destroy

  def create
    membership = @group.join(dependant)
    track_event "dependant-added", existing: true, group_age: @group.created_at if membership.previously_new_record?
    redirect_to @group, notice: t(".added", name: dependant.name)
  end

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

    def dependant
      @dependant ||= Current.user.dependants.find(params.expect(membership: [ :user_id ]).fetch(:user_id))
    end

    def ensure_removable
      head :forbidden unless @membership.removable_by?(Current.user)
    end

    def redirect_after_removal
      if @membership.user == Current.user
        track_event "group-left", group_age: @group.created_at
        redirect_to root_path, notice: t(".left", group: @group.name)
      else
        track_event "member-removed", group_age: @group.created_at
        redirect_to @group, notice: t(".removed", name: @membership.user.name)
      end
    end
end
