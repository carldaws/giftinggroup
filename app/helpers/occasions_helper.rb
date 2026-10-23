module OccasionsHelper
  def occasion_title(occasion)
    if occasion.person == Current.user && occasion.person.birth_year.present?
      t("occasions.your_birthday_with_age", ordinal: occasion.person.age_on(occasion.date).ordinalize)
    elsif occasion.person == Current.user
      t("occasions.your_birthday")
    else
      occasion.title
    end
  end

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
