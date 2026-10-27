module ItemsHelper
  def status_for(reservation, with_occasion: true)
    occasion = with_occasion ? reservation.occasion : nil

    if reservation.waiting? || reservation.sharers.any?
      split_status_for(reservation, occasion:)
    else
      who = reservation.user == Current.user ? "you" : "they"
      translate_for_occasion("items.item.status.#{who}_#{stage_of(reservation)}", occasion, name: reservation.user.name)
    end
  end

  def splitting_with(reservation)
    t("items.item.splitting_with", names: names_of(reservation.people - [ Current.user ]))
  end

  def split_status_for(reservation, occasion:)
    translate_for_occasion("items.item.split_status.#{split_state_of(reservation)}", occasion,
      name: reservation.user.name, names: names_of(reservation.people), others: names_of(reservation.people - [ Current.user ]), count: reservation.places_left).upcase_first
  end

  def split_state_of(reservation)
    case
    when reservation.waiting? && reservation.user == Current.user then "you_waiting"
    when reservation.waiting? && reservation.sharers.include?(Current.user) then "joined_waiting"
    when reservation.waiting? then "they_waiting"
    else stage_of(reservation)
    end
  end

  def stage_of(reservation)
    case
    when reservation.given? then "gave"
    when reservation.bought? then "bought"
    else "getting"
    end
  end

  def names_of(people)
    people.map { it == Current.user ? t("items.item.you") : it.name }.to_sentence
  end

  def translate_for_occasion(key, occasion, **options)
    occasion.present? ? t("#{key}_for", occasion: occasion.title, **options) : t(key, **options)
  end
end
