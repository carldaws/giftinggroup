class PeopleController < ApplicationController
  before_action :set_person
  before_action :ensure_looks_after_dependant, only: :destroy

  def show
  end

  def destroy
    @person.delete_account
    redirect_to root_path, notice: t(".deleted", name: @person.name)
  end

  private
    def set_person
      @person = User.visible_to(Current.user).find(params[:id])
    end

    def ensure_looks_after_dependant
      head :forbidden unless Current.user.looks_after?(@person) && !@person.signs_in?
    end
end
