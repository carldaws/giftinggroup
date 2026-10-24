class ItemsController < ApplicationController
  before_action :set_item
  before_action :ensure_item_editable

  def edit
  end

  def update
    if @item.update(item_params_keeping_existing_photos)
      redirect_to person_path(@item.owner), notice: t(".updated", name: @item.title)
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @item.remove
    redirect_to person_path(@item.owner), notice: t(".removed", name: @item.title)
  end

  private
    def set_item
      @item = Item.visible_to(Current.user).find(params[:id])
    end

    def ensure_item_editable
      head :forbidden unless @item.editable_by?(Current.user)
    end

    def item_params_keeping_existing_photos
      params.expect(item: [ :name, :url, :price, :notes, :quantity, :most_wanted, :little, photos: [] ]).tap do |attributes|
        attributes[:photos] = @item.photos.blobs + attributes[:photos] if attributes[:photos].present?
      end
    end
end
