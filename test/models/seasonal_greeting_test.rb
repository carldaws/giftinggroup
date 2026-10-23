require "test_helper"

class SeasonalGreetingTest < ActiveSupport::TestCase
  test "occasions through the year" do
    {
      Date.new(2026, 1, 3) => :new_year,
      Date.new(2026, 2, 14) => :valentines_day,
      Date.new(2026, 10, 23) => :halloween,
      Date.new(2026, 11, 5) => :bonfire_night,
      Date.new(2026, 12, 25) => :christmas,
      Date.new(2026, 12, 31) => :new_year
    }.each do |date, occasion|
      assert_equal occasion, SeasonalGreeting.occasion_on(date), date
    end
  end

  test "an everyday greeting between occasions" do
    assert_equal :everyday, SeasonalGreeting.occasion_on(Date.new(2026, 7, 1))
  end

  test "every occasion has a greeting" do
    [ *SeasonalGreeting::OCCASIONS.keys, :everyday ].each do |occasion|
      assert I18n.exists?(occasion, scope: :seasonal_greetings), occasion
    end
  end
end
