class Share < ApplicationRecord
  belongs_to :reservation
  belongs_to :user

  validate :reservation_is_a_split, :user_can_split_it, if: -> { reservation.present? && user.present? }
  validate :split_has_room, :split_is_not_bought, :item_is_still_wanted, :user_is_not_already_getting_it, on: :create, if: -> { reservation.present? && errors.none? }

  def leave
    reservation.with_lock do
      if reservation.bought?
        errors.add(:base, :already_bought)
      else
        destroy
      end
    end
  end

  private
    def reservation_is_a_split
      errors.add(:base, :not_a_split) unless reservation.split?
    end

    def user_can_split_it
      errors.add(:base, :cannot_split_it) unless User.who_can_split_gifts_to(reservation.item.owner, with: reservation.user).exists?(user.id)
    end

    def split_has_room
      errors.add(:base, :split_full) if reservation.shares.count >= reservation.split_with
    end

    def split_is_not_bought
      errors.add(:base, :already_bought) if reservation.bought?
    end

    def item_is_still_wanted
      errors.add(:base, :no_longer_wanted) unless reservation.item.still_wanted?
    end

    def user_is_not_already_getting_it
      errors.add(:base, :already_getting_it) if reservation.item.reservations.involving(user).exists?
    end
end
