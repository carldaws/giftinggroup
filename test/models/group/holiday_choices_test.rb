require "test_helper"

class Group::HolidayChoicesTest < ActiveSupport::TestCase
  test "a new group is offered the holidays everyone shares, with Christmas ticked" do
    choices = Group::HolidayChoices.new(groups(:ivies), welcome: true)
    christmas = Holiday.find("christmas_day")

    assert choices.holidays.all?(&:for_everyone?)
    assert choices.checked?(christmas)
  end

  test "afterwards only the holidays the group celebrates are ticked" do
    groups(:ivies).celebrate([ "easter_sunday" ])
    choices = Group::HolidayChoices.new(groups(:ivies))

    assert choices.checked?(Holiday.find("easter_sunday"))
    assert_not choices.checked?(Holiday.find("christmas_day"))
  end

  test "it knows who a holiday is for" do
    holiday = Holiday.all.reject(&:for_everyone?).first
    groups(:ivies).celebrate([ holiday.key ], people: { holiday.key => [ users(:erin).id ] })
    choices = Group::HolidayChoices.new(groups(:ivies))

    assert choices.celebrating?(holiday, users(:erin))
    assert_not choices.celebrating?(holiday, users(:carol))
  end
end
