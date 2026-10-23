class People::ItemsController < ApplicationController
  include PersonScoped

  def new
    @item = @person.build_item({ little: params[:little].present? }, by: Current.user)
  end

  def create
    @item = @person.build_item(item_params, by: Current.user)

    if @item.save
      redirect_to person_path(@person), notice: t(@item.suggestion? ? ".suggested" : ".added", name: @item.name)
    else
      render :new, status: :unprocessable_content
    end
  end

  private
    def item_params
      params.expect(item: [ :name, :url, :price, :notes, :quantity, :most_wanted, :little, photos: [] ])
    end
end
