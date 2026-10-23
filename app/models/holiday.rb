class Holiday
  attr_reader :key

  def initialize(key, for_everyone:, &date_in)
    @key = key
    @for_everyone = for_everyone
    @date_in = date_in
  end

  class << self
    def all
      ALL
    end

    def find(key)
      ALL.find { it.key == key.to_s } or raise ActiveRecord::RecordNotFound, "No holiday called #{key}"
    end

    def keys
      ALL.map(&:key)
    end

    def for_everyone_keys
      ALL.select(&:for_everyone?).map(&:key)
    end

    def easter_in(year)
      golden = year % 19
      century, year_of_century = year.divmod(100)
      leap_centuries, century_remainder = century.divmod(4)
      correction = (century + 8) / 25
      moon = (century - correction + 1) / 3
      epact = (19 * golden + century - leap_centuries - moon + 15) % 30
      leap_years, year_remainder = year_of_century.divmod(4)
      weekday = (32 + 2 * century_remainder + 2 * leap_years - epact - year_remainder) % 7
      offset = (golden + 11 * epact + 22 * weekday) / 451
      month, day = (epact + weekday - 7 * offset + 114).divmod(31)

      Date.new(year, month, day + 1)
    end

    def nth_sunday(year, month, n)
      first = Date.new(year, month, 1)
      first + ((7 - first.wday) % 7) + (n - 1) * 7
    end
  end

  def name
    I18n.t("holidays.#{key}")
  end

  def for_everyone?
    @for_everyone
  end

  def date_in(year)
    @date_in.call(year)
  end

  def occasions
    Occasion.where(holiday_key: key)
  end

  def next_date(from: Date.current)
    this_year = date_in(from.year)
    this_year < from ? date_in(from.year + 1) : this_year
  end

  ALL = [
    new("christmas_day", for_everyone: true) { |year| Date.new(year, 12, 25) },
    new("christmas_eve", for_everyone: true) { |year| Date.new(year, 12, 24) },
    new("st_nicholas_day", for_everyone: true) { |year| Date.new(year, 12, 6) },
    new("easter_sunday", for_everyone: true) { |year| easter_in(year) },
    new("valentines_day", for_everyone: false) { |year| Date.new(year, 2, 14) },
    new("mothers_day_uk", for_everyone: false) { |year| easter_in(year) - 21 },
    new("mothers_day_us", for_everyone: false) { |year| nth_sunday(year, 5, 2) },
    new("fathers_day", for_everyone: false) { |year| nth_sunday(year, 6, 3) }
  ].freeze
end
