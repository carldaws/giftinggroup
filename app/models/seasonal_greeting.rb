class SeasonalGreeting
  OCCASIONS = {
    new_year: [ [ 1, 1 ]..[ 1, 7 ], [ 12, 27 ]..[ 12, 31 ] ],
    valentines_day: [ [ 2, 10 ]..[ 2, 14 ] ],
    halloween: [ [ 10, 20 ]..[ 10, 31 ] ],
    bonfire_night: [ [ 11, 1 ]..[ 11, 5 ] ],
    christmas: [ [ 12, 1 ]..[ 12, 26 ] ]
  }.freeze

  class << self
    def occasion_on(date)
      day = [ date.month, date.day ]
      occasion, _ = OCCASIONS.find { |_, periods| periods.any? { it.cover?(day) } }
      occasion || :everyday
    end
  end
end
