class Items::ReceiptsController < ApplicationController
  include ItemScoped

  before_action :ensure_item_receivable

  def create
    @item.receive
    track_event "item-received"
    redirect_to person_path(@item.owner), notice: t(".received", name: @item.title)
  end

  def destroy
    @item.unreceive
    redirect_back_or_to_list
  end

  private
    def ensure_item_receivable
      head :forbidden unless @item.receivable_by?(Current.user)
    end
end
