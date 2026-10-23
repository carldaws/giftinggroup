class PeopleController < ApplicationController
  def show
    @person = User.visible_to(Current.user).find(params[:id])
  end
end
