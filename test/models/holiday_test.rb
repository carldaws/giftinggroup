require "test_helper"

class HolidayTest < ActiveSupport::TestCase
  test "Easter falls on the right Sunday" do
    {
      2024 => Date.new(2024, 3, 31),
      2025 => Date.new(2025, 4, 20),
      2026 => Date.new(2026, 4, 5),
      2027 => Date.new(2027, 3, 28),
      2038 => Date.new(2038, 4, 25)
    }.each do |year, easter|
      assert_equal easter, Holiday.easter_in(year), year
    end
  end

  test "Mothering Sunday is three weeks before Easter" do
    assert_equal Date.new(2026, 3, 15), Holiday.find("mothers_day_uk").date_in(2026)
    assert_equal Date.new(2027, 3, 7), Holiday.find("mothers_day_uk").date_in(2027)
  end

  test "Mother's Day in the US is the second Sunday in May" do
    assert_equal Date.new(2026, 5, 10), Holiday.find("mothers_day_us").date_in(2026)
    assert_equal Date.new(2027, 5, 9), Holiday.find("mothers_day_us").date_in(2027)
  end

  test "Father's Day is the third Sunday in June" do
    assert_equal Date.new(2026, 6, 21), Holiday.find("fathers_day").date_in(2026)
    assert_equal Date.new(2027, 6, 20), Holiday.find("fathers_day").date_in(2027)
  end

  test "the next date rolls into next year once this year's has passed" do
    christmas = Holiday.find("christmas_day")

    assert_equal Date.new(2026, 12, 25), christmas.next_date(from: Date.new(2026, 12, 25))
    assert_equal Date.new(2027, 12, 25), christmas.next_date(from: Date.new(2026, 12, 26))
  end

  test "every holiday has a name" do
    Holiday.all.each { assert I18n.exists?("holidays.#{it.key}"), it.key }
  end

  test "unknown holidays aren't found" do
    assert_raises(ActiveRecord::RecordNotFound) { Holiday.find("talk_like_a_pirate_day") }
  end
end
