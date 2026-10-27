module PeopleHelper
  def wishlist_path(wishlist, little: wishlist.little_only?, surprises_shown: wishlist.surprises_shown?, **options)
    person_path(wishlist.person, show: (little ? "little" : nil), surprises: (surprises_shown ? "shown" : nil), **options)
  end

  def next_birthday_of(person)
    if person.birthday?
      t("people.show.birthday", date: l(person.next_birthday, format: "%-d %B"), countdown: countdown_to(person.next_birthday).downcase_first)
    end
  end

  def deletion_consequences_for(person)
    picked, other_guardians = person.picked_items_count, person.other_guardians(than: Current.user)

    [
      t("people.deletions.new.list", name: person.name),
      t("people.deletions.new.chats", name: person.name),
      (t("people.deletions.new.picked", count: picked) if picked.positive?),
      (t("people.deletions.new.guardians", names: other_guardians.map(&:name).to_sentence, count: other_guardians.size, name: person.name) if other_guardians.any?)
    ].compact
  end

  def account_deletion_consequences_for(user)
    dependants, groups = user.dependants_nobody_else_looks_after, user.groups_without_another_adult

    [
      t("account_deletions.new.your_list"),
      t("account_deletions.new.reservations"),
      t("account_deletions.new.ideas"),
      t("account_deletions.new.messages"),
      (t("account_deletions.new.dependants_html", names: to_sentence(dependants.map { tag.strong(it.name) }), count: dependants.size) if dependants.any?),
      (t("account_deletions.new.groups_html", names: to_sentence(groups.map { tag.strong(it.name) }), count: groups.size) if groups.any?)
    ].compact
  end

  def details_label_for(wishlist)
    t(wishlist.yours? ? "people.show.your_details" : "people.show.edit_details")
  end

  def surprises_toggle_label_for(wishlist)
    t(wishlist.surprises_hidden? ? "people.show.show_surprises" : "people.show.hide_surprises")
  end

  def list_heading_for(wishlist)
    wishlist.yours? ? t("people.show.your_list") : t("people.show.their_list", name: wishlist.person.name)
  end

  def add_item_label_for(wishlist)
    t(wishlist.looked_after? ? "people.show.add_item" : "people.show.suggest_item")
  end

  def passed_occasion_notice_for(wishlist)
    occasion = wishlist.passed_occasion

    case
    when !wishlist.yours? then t("people.show.occasion_passed_for", occasion: occasion.title, name: wishlist.person.name)
    when occasion.birthday? then t("people.show.birthday_passed")
    else t("people.show.occasion_passed", name: occasion.title)
    end
  end

  def empty_list_message_for(wishlist)
    name = wishlist.person.name

    case
    when wishlist.little_only? && wishlist.looked_after? then t("people.show.little_empty_yours")
    when wishlist.little_only? then t("people.show.little_empty", name:)
    when wishlist.yours? then t("people.show.list_empty_yours")
    when wishlist.looked_after? then t("people.show.list_empty_looked_after", name:)
    else t("people.show.list_empty", name:)
    end
  end
end
