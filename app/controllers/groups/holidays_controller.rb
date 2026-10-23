class Groups::HolidaysController < ApplicationController
  include GroupScoped

  before_action :ensure_admin

  def edit
  end

  def update
    @group.celebrate(holiday_params.fetch(:keys, []), people: (holiday_params[:people] || {}).to_h)

    if params[:welcome].present?
      redirect_to @group, notice: t(".all_set")
    else
      redirect_to @group, notice: t(".saved")
    end
  end

  private
    def holiday_params
      params.permit(keys: [], people: Holiday.keys.index_with { [] })
    end
end
