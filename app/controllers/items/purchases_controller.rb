class Items::PurchasesController < ApplicationController
  include ItemScoped

  def create
    Current.user.reservations.find_by!(item: @item).buy
    redirect_back_or_to_list
  end

  def destroy
    Current.user.reservations.find_by!(item: @item).unbuy
    redirect_back_or_to_list
  end
end
