class Items::PhotosController < ApplicationController
  include ItemScoped

  before_action :ensure_item_editable

  def destroy
    @item.photos.find(params[:id]).purge_later
    redirect_to edit_item_path(@item)
  end
end
