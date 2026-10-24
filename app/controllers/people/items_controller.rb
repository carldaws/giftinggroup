class People::ItemsController < ApplicationController
  include PersonScoped, ItemPhotos

  def new
    @item = @person.build_item({ little: params[:little].present? }, by: Current.user)
  end

  def create
    @item = @person.build_item(item_params, by: Current.user, asked_for: params.dig(:item, :asked_for) == "1")

    if @item.save
      redirect_to person_path(@person), notice: added_notice
    else
      render :new, status: :unprocessable_content
    end
  end

  private
    def item_params
      with_own_fetched_photos(params.expect(item: [ :name, :url, :price, :notes, :quantity, :most_wanted, :little, photos: [] ]))
    end

    def added_notice
      if @item.suggestion? && Current.user.looks_after?(@person)
        t(".added_quietly")
      else
        t(@item.suggestion? ? ".suggested" : ".added", name: @item.title)
      end
    end
end
