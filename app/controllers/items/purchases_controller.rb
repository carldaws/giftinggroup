class Items::PurchasesController < ApplicationController
  include ItemScoped

  def create
    reservation = Current.user.reservations.find_by!(item: @item)
    reservation.buy

    if reservation.errors.none?
      redirect_back_or_to_list
    else
      redirect_back_or_to_list alert: reservation.errors.full_messages.to_sentence
    end
  end

  def destroy
    Current.user.reservations.find_by!(item: @item).unbuy
    redirect_back_or_to_list
  end
end
