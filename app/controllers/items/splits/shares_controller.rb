class Items::Splits::SharesController < ApplicationController
  include ItemScoped

  before_action :set_split

  def create
    share = @split.join(Current.user)

    if share.persisted?
      redirect_back_or_to_list
    else
      redirect_back_or_to_list alert: share.errors.full_messages.to_sentence
    end
  end

  def destroy
    share = @split.shares.find_by!(user: Current.user)
    share.leave

    if share.destroyed?
      redirect_back_or_to_list
    else
      redirect_back_or_to_list alert: share.errors.full_messages.to_sentence
    end
  end

  private
    def set_split
      @split = Reservation.visible_to(Current.user).splits.where(item: @item).find(params[:split_id])
    end
end
