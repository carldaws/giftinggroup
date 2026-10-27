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

  def new_item_heading(item)
    case
    when item.surprise? then t("people.items.new.suggest_heading", name: item.owner.name)
    when item.little? then t("people.items.new.little_heading")
    else t("people.items.new.heading")
    end
  end

  def item_title_link(item)
    if item.removed?
      tag.p(item.title, class: "row-title")
    else
      link_to item.title, person_path(item.owner, anchor: dom_id(item)), class: "row-title link text-ink"
    end
  end

  def split_note_tag(split)
    if !split.item.still_wanted?
      note_tag t("groups.splits.no_longer_wanted", name: split.item.owner.name)
    elsif split.started_by?(Current.user) && !split.fillable?
      note_tag t("groups.splits.not_enough_people")
    end
  end

  def note_tag(text)
    tag.p(text, class: "mt-1 text-base font-medium text-honey-ink")
  end

  def item_details_tag(item)
    quantity = item.unlimited? ? t("items.item.as_many_as_you_like") : (t("items.item.wants", count: item.quantity) if item.quantity > 1)
    details = [ item.price.presence, quantity ].compact

    tag.p(details.join(" · "), class: "row-meta mt-0.5") if details.any?
  end

  def split_options_for(card)
    (1..card.split_limit).map { [ t("items.item.split_others", count: it), it ] }
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
