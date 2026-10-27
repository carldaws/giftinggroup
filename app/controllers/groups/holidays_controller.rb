class Groups::HolidaysController < ApplicationController
  include GroupScoped

  def edit
    @choices = Group::HolidayChoices.new(@group, welcome: params[:welcome].present?)
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
