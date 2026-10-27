class PeopleController < ApplicationController
  def show
    @wishlist = Wishlist.new(User.visible_to(Current.user).find(params[:id]), viewer: Current.user,
      little_only: params[:show] == "little", surprises_shown: params[:surprises] == "shown")
  end
end
