class Items::ReservationsController < ApplicationController
  include ItemScoped

  def create
    reservation = @item.reserve_for(Current.user)

    if reservation.persisted?
      redirect_to_list
    else
      redirect_to_list alert: reservation.errors.full_messages.to_sentence
    end
  end

  def destroy
    Current.user.reservations.find_by!(item: @item).destroy
    redirect_to_list
  end
end
