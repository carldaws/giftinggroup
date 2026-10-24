module ItemsHelper
  def status_for(reservation, with_occasion: true)
    who = reservation.user == Current.user ? "you" : "they"
    what =
      case
      when reservation.given? then "gave"
      when reservation.bought? then "bought"
      else "getting"
      end

    if with_occasion && reservation.occasion.present?
      t("items.item.status.#{who}_#{what}_for", name: reservation.user.name, occasion: reservation.occasion.title)
    else
      t("items.item.status.#{who}_#{what}", name: reservation.user.name)
    end
  end
end
