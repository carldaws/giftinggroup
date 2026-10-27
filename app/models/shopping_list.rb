class ShoppingList
  include Enumerable

  def initialize(user)
    @user = user
  end

  def each(&)
    reservations.each(&)
  end

  def to_buy
    reject(&:bought?)
  end

  def bought
    select(&:bought?)
  end

  private
    def reservations
      @reservations ||= begin
        reservations = Reservation.visible_to(@user).involving(@user).includes(:user, :shares, :sharers, occasion: :person, item: :owner).reject { it.waiting? || it.given? }
        dated, undated = reservations.partition { it.occasion.present? }

        dated.sort_by { [ it.occasion.date, it.item.owner.name.downcase ] } + undated.sort_by { it.item.owner.name.downcase }
      end
    end
end
