class Reservation < ApplicationRecord
  belongs_to :item
  belongs_to :user

  validate :user_can_see_the_list, :user_is_not_the_list_owner, if: -> { item.present? && user.present? }

  scope :visible_to, ->(user) do
    where(item: Item.visible_to(user)).where.not(item: Item.where(list: user.lists))
  end

  def bought?
    bought_at.present?
  end

  private
    def user_can_see_the_list
      errors.add(:user, :cannot_see_the_list) unless item.list.visible_to?(user)
    end

    def user_is_not_the_list_owner
      errors.add(:user, :owns_the_list) if item.list.owned_by?(user)
    end
end
