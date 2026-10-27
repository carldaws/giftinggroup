class Wishlist
  attr_reader :person, :viewer

  def initialize(person, viewer:, little_only: false, surprises_shown: false)
    @person, @viewer, @little_only, @surprises_shown = person, viewer, little_only, surprises_shown
  end

  def yours?
    person == viewer
  end

  def looked_after?
    viewer.looks_after?(person)
  end

  def surprises_toggle?
    looked_after? && !yours?
  end

  def little_only?
    @little_only
  end

  def surprises_shown?
    surprises_toggle? && @surprises_shown
  end

  def surprises_hidden?
    looked_after? && !surprises_shown?
  end

  def wanted_count
    @wanted_count ||= wanted.count
  end

  def little_count
    @little_count ||= wanted.little.count
  end

  def cards
    @cards ||= shown.map { Item::Card.new(it, wishlist: self, reservations: reservations.fetch(it.id, [])) }
  end

  def still_wanted_cards
    cards.reject(&:given?)
  end

  def given_cards
    cards.select(&:given?)
  end

  def received
    @received ||= looked_after? ? items.received.where(suggested_by: nil).to_a : []
  end

  def passed_occasion
    unless defined?(@passed_occasion)
      @passed_occasion = looked_after? ? Occasion.applying_to(person).recent.order(date: :desc).first : nil
    end

    @passed_occasion
  end

  def chats
    @chats ||= person.memberships.with_chat_visible_to(viewer).includes(:group).sort_by { it.group.name.downcase }
  end

  def unread_count_in(chat)
    unread_counts.fetch(chat.id, 0)
  end

  def occasion_choices
    @occasion_choices ||= surprises_hidden? ? [] : Occasion.for_gifts_to(person, from: viewer).upcoming.soonest_first.includes(:person).to_a
  end

  def split_candidates
    @split_candidates ||= surprises_hidden? ? [] : User.who_can_split_gifts_to(person, with: viewer).to_a
  end

  private
    def unread_counts
      @unread_counts ||= Message.unread_by(viewer).where(subject: chats).group(:subject_id).count
    end

    def items
      @items ||= begin
        items = person.items.listed.visible_to(viewer).includes(:suggested_by, photos_attachments: { blob: { variant_records: { image_attachment: :blob } } }).in_list_order
        surprises_hidden? ? items.where(suggested_by: nil) : items
      end
    end

    def wanted
      items.wanted
    end

    def shown
      little_only? ? wanted.little : wanted
    end

    def reservations
      @reservations ||= surprises_hidden? ? {} : Reservation.visible_to(viewer).where(item: shown).includes(:user, :shares, :sharers, occasion: :person).group_by(&:item_id)
    end
end
