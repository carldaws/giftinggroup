class Items::ReservationsController < ApplicationController
  include ItemScoped

  def create
    reservation = @item.reserve_for(Current.user, split_with: params.dig(:reservation, :split_with))

    if reservation.persisted?
      redirect_back_or_to_list
    else
      redirect_back_or_to_list alert: reservation.errors.full_messages.to_sentence
    end
  end

  def update
    reservation = Current.user.reservations.find_by!(item: @item)

    if reservation.update(params.expect(reservation: [ :occasion_id ]))
      redirect_back_or_to_list
    else
      redirect_back_or_to_list alert: reservation.errors.full_messages.to_sentence
    end
  end

  def destroy
    Current.user.reservations.find_by!(item: @item).destroy
    redirect_back_or_to_list
  end
end
