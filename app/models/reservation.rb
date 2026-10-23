class Reservation < ApplicationRecord
  belongs_to :item
  belongs_to :user

  validate :user_can_see_the_item, :user_is_not_the_owner, if: -> { item.present? && user.present? }
  validate :item_is_still_wanted, :item_is_still_available, on: :create, if: -> { item.present? && errors.none? }

  scope :visible_to, ->(user) do
    where(item: Item.visible_to(user)).where.not(item: Item.where(owner: user))
  end

  def bought?
    bought_at.present?
  end

  def buy
    update!(bought_at: Time.current)
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

    def item_is_still_wanted
      errors.add(:item, :received) if item.received?
    end

    def item_is_still_available
      errors.add(:item, :fully_reserved) if !item.unlimited? && Reservation.where(item:).count >= item.quantity
    end
end
