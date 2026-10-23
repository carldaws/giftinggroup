module GroupScoped
  extend ActiveSupport::Concern

  included do
    before_action :set_group
  end

  private
    def set_group
      @group = Current.user.groups.find(params[:group_id])
    end

    def ensure_admin
      head :forbidden unless @group.admin?(Current.user)
    end
end
