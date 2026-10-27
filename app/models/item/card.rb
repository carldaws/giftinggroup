class Item::Card
  attr_reader :item, :reservations

  delegate :viewer, :occasion_choices, :split_candidates, :surprises_hidden?, to: :@wishlist

  def initialize(item, wishlist:, reservations: [])
    @item, @wishlist, @reservations = item, wishlist, reservations
  end

  def reservations_shown?
    !surprises_hidden?
  end

  def actions?
    reservations_shown? || editable? || receivable?
  end

  def badges?
    item.most_wanted? || item.little? || item.suggestion?
  end

  def main_photo
    item.photos.first
  end

  def extra_photos
    item.photos.drop(1)
  end

  def my_reservation
    reservations.find { it.user == viewer }
  end

  def joined_split
    reservations.find { it.sharers.include?(viewer) }
  end

  def joinable_splits
    involved? ? [] : reservations.select(&:waiting?)
  end

  def reservable?
    item.unlimited? || (reservations - [ my_reservation ]).size < item.quantity
  end

  def split_limit
    (split_candidates - reservations.flat_map(&:people)).size
  end

  def splittable?
    split_limit.positive?
  end

  def choosing_occasion?
    my_reservation.present? && !my_reservation.given? && occasion_choices.any?
  end

  def occasion_shown_for?(reservation)
    !(choosing_occasion? && reservation == my_reservation)
  end

  def editable?
    item.editable_by?(viewer)
  end

  def receivable?
    item.receivable_by?(viewer)
  end

  def given?
    item.given_with?(reservations)
  end

  private
    def involved?
      reservations.any? { it.people.include?(viewer) }
    end
end
