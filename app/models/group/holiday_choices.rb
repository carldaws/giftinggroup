class Group::HolidayChoices
  attr_reader :group

  def initialize(group, welcome: false)
    @group, @welcome = group, welcome
  end

  def welcome?
    @welcome
  end

  def holidays
    (welcome? ? Holiday.all.select(&:for_everyone?) : Holiday.all).sort_by(&:next_date)
  end

  def members
    @members ||= group.members_by_name
  end

  def checked?(holiday)
    celebrated.key?(holiday.key) || (welcome? && celebrated.empty? && holiday.key == "christmas_day")
  end

  def celebrating?(holiday, member)
    celebrated.key?(holiday.key) && celebrated[holiday.key].recipients.include?(member)
  end

  private
    def celebrated
      @celebrated ||= group.group_holidays.includes(:recipients).index_by(&:key)
    end
end
