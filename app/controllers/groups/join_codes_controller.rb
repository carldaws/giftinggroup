class Groups::JoinCodesController < ApplicationController
  include GroupScoped

  before_action :ensure_admin

  def update
    @group.regenerate_join_code
    redirect_to @group, notice: t(".regenerated")
  end
end
