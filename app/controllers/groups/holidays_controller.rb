class Groups::HolidaysController < ApplicationController
  include GroupScoped

  def edit
    @choices = Group::HolidayChoices.new(@group, welcome: params[:welcome].present?)
  end

  def update
    keys = holiday_params.fetch(:keys, [])

    @group.celebrate(keys, people: (holiday_params[:people] || {}).to_h)
    track_event "holidays-chosen", holidays: keys.size, first_time: welcome?, group_age: @group.created_at

    if welcome?
      redirect_to @group, notice: t(".all_set")
    else
      redirect_to @group, notice: t(".saved")
    end
  end

  private
    def welcome?
      params[:welcome].present?
    end

    def holiday_params
      params.permit(keys: [], people: Holiday.keys.index_with { [] })
    end
end
