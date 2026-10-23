module OccasionsHelper
  def countdown_to(date)
    days = (date - Date.current).to_i

    if days.zero?
      t("occasions.countdown.today")
    elsif days == 1
      t("occasions.countdown.tomorrow")
    elsif days < 14
      t("occasions.countdown.days", count: days)
    elsif days < 60
      t("occasions.countdown.weeks", count: days / 7)
    else
      t("occasions.countdown.months", count: (days / 30.4).round)
    end
  end
end
