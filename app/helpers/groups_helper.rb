module GroupsHelper
  def guardian_names(person)
    names_with_you(person.guardians)
  end

  def names_with_you(people)
    people.map { it == Current.user ? t("groups.membership.you_lowercase") : it.name }.to_sentence
  end

  def invite_url_for(group)
    join_url(group.join_code)
  end

  def invite_url_text_for(group)
    safe_join([ invite_url_for(group).delete_suffix(group.join_code), tag.wbr, tag.span(group.join_code, class: "whitespace-nowrap") ])
  end

  def occasion_people_for(occasion, group)
    people = occasion.people_in(group)
    people.any? ? t("groups.coming_up.for_people", names: names_with_you(people)) : t("groups.coming_up.for_no_one_yet")
  end

  def your_list_title_for(wishlist)
    wishlist.yours? ? t("groups.your_lists.yours") : t("groups.your_lists.theirs", name: wishlist.person.name)
  end

  def your_list_summary_for(wishlist)
    case
    when wishlist.wanted_count.positive? then t("groups.your_lists.things", count: wishlist.wanted_count)
    when wishlist.yours? then t("groups.your_lists.empty_yours")
    else t("groups.your_lists.empty_theirs", name: wishlist.person.name)
    end
  end

  def shopping_list_occasion_for(reservation)
    occasion, owner = reservation.occasion, reservation.item.owner

    case
    when occasion.nil? then t("groups.shopping_list.for", name: owner.name)
    when occasion.person == owner then t("groups.shopping_list.their_occasion", occasion: occasion.title, countdown: countdown_to(occasion.date).downcase_first)
    else t("groups.shopping_list.for_occasion", name: owner.name, occasion: occasion.title, countdown: countdown_to(occasion.date).downcase_first)
    end
  end

  def shopping_list_note_tag(reservation)
    item = reservation.item

    if item.removed?
      note_tag t("groups.shopping_list.removed")
    elsif item.received?
      note_tag t("groups.shopping_list.already_has", name: item.owner.name)
    end
  end
end
