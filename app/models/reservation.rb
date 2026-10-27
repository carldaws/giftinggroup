class Reservation < ApplicationRecord
  belongs_to :item
  belongs_to :user
  belongs_to :occasion, optional: true

  has_many :shares, dependent: :destroy
  has_many :sharers, through: :shares, source: :user

  validates :split_with, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validate :user_can_see_the_item, :user_is_not_the_owner, if: -> { item.present? && user.present? }
  validate :split_fits_the_people_who_can_join, on: :create, if: -> { split? && item.present? && user.present? && errors.none? }
  validate :split_is_complete_before_buying, if: -> { will_save_change_to_bought_at? && bought? }
  validate :item_is_still_listed, :item_is_still_wanted, :item_is_still_available, on: :create, if: -> { item.present? && errors.none? }
  validate :user_is_not_already_splitting_it, on: :create, if: -> { item.present? && user.present? && errors.none? }
  validate :occasion_is_for_gifts_to_the_owner, if: -> { will_save_change_to_occasion_id? && occasion_id.present? && errors.none? }
  validate :given_gifts_keep_their_occasion, on: :update, if: :will_save_change_to_occasion_id?

  after_create :clear_release_note, if: -> { item.released_by_name.present? }
  after_destroy :forget_removed_item, unless: :destroyed_with_item?

  scope :visible_to, ->(user) do
    where(item: Item.visible_to(user)).where.not(item: Item.where(owner: user))
  end
  scope :splits, -> { where.not(split_with: nil) }
  scope :unbought, -> { where(bought_at: nil) }
  scope :involving, ->(user) { where(user:).or(where(id: Share.where(user:).select(:reservation_id))) }

  def bought?
    bought_at.present?
  end

  def given?
    bought? && occasion.present? && occasion.passed?
  end

  def split?
    split_with.present?
  end

  def places_left
    split? ? split_with - shares.size : 0
  end

  def waiting?
    split? && !bought? && places_left.positive?
  end

  def people
    [ user, *sharers ]
  end

  def fillable?
    item.people_to_split_with(user).count >= places_left
  end

  def joinable_by?(person)
    waiting? && item.still_wanted? && item.reservations.none? { it.people.include?(person) }
  end

  def join(person)
    item.with_lock { shares.find_or_create_by(user: person) }
  end

  def hand_over
    successor = shares.sort_by(&:created_at).find { Item.visible_to(it.user).exists?(item_id) }

    if successor.present?
      transaction do
        successor.destroy!
        update!(user: successor.user)
      end
    end
  end

  def give_up
    hand_over || destroy
  end

  def buy
    with_lock { update(bought_at: Time.current) }
  end

  def unbuy
    update!(bought_at: nil)
  end

  private
    def user_can_see_the_item
      errors.add(:user, :cannot_see_the_list) unless Item.visible_to(user).exists?(item.id)
    end

    def user_is_not_the_owner
      errors.add(:user, :owns_the_list) if item.owner == user
    end

    def item_is_still_listed
      errors.add(:item, :removed) if item.removed?
    end

    def split_fits_the_people_who_can_join
      available = item.people_to_split_with(user).count
      errors.add(:split_with, :too_many, count: available) if split_with > available
    end

    def split_is_complete_before_buying
      errors.add(:base, :split_incomplete) if places_left.positive?
    end

    def clear_release_note
      item.update_column(:released_by_name, nil)
    end

    def forget_removed_item
      item.with_lock { item.destroy! if item.removed? && item.reservations.none? }
    end

    def destroyed_with_item?
      destroyed_by_association.present? && destroyed_by_association.active_record == Item
    end

    def item_is_still_wanted
      errors.add(:item, :received) if item.received?
    end

    def user_is_not_already_splitting_it
      errors.add(:base, :already_getting_it) if Share.where(reservation: item.reservations, user:).exists?
    end

    def item_is_still_available
      errors.add(:item, :fully_reserved) if !item.unlimited? && Reservation.where(item:).count >= item.quantity
    end

    def occasion_is_for_gifts_to_the_owner
      errors.add(:occasion, :not_for_this_person) unless Occasion.for_gifts_to(item.owner, from: user).exists?(occasion_id)
    end

    def given_gifts_keep_their_occasion
      previous = Occasion.find_by(id: occasion_id_in_database)
      errors.add(:occasion, :already_given) if bought? && previous.present? && previous.passed?
    end
end
