module ItemsHelper
  def status_for(reservation, with_occasion: true)
    return split_status_for(reservation, with_occasion:) if reservation.waiting? || reservation.sharers.any?

    who = reservation.user == Current.user ? "you" : "they"
    what = stage_of(reservation)

    if with_occasion && reservation.occasion.present?
      t("items.item.status.#{who}_#{what}_for", name: reservation.user.name, occasion: reservation.occasion.title)
    else
      t("items.item.status.#{who}_#{what}", name: reservation.user.name)
    end
  end

  def splitting_with(reservation)
    t("items.item.splitting_with", names: (reservation.people - [ Current.user ]).map(&:name).to_sentence)
  end

  def split_status_for(reservation, with_occasion: true)
    names = reservation.people.map { it == Current.user ? t("items.item.you") : it.name }.to_sentence
    others = (reservation.people - [ Current.user ]).map(&:name).to_sentence
    state =
      case
      when !reservation.waiting? then stage_of(reservation)
      when reservation.user == Current.user then "you_waiting"
      when reservation.sharers.include?(Current.user) then "joined_waiting"
      else "they_waiting"
      end
    options = { name: reservation.user.name, names:, others:, count: reservation.places_left }

    if with_occasion && reservation.occasion.present?
      state += "_for"
      options[:occasion] = reservation.occasion.title
    end

    t("items.item.split_status.#{state}", **options).upcase_first
  end

  def stage_of(reservation)
    case
    when reservation.given? then "gave"
    when reservation.bought? then "bought"
    else "getting"
    end
  end
end
