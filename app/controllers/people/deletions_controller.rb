class People::DeletionsController < ApplicationController
  include PersonScoped

  before_action :ensure_looks_after_person, :ensure_looked_after

  def new
  end

  def create
    @person.delete_account
    redirect_to root_path, notice: t(".deleted", name: @person.name)
  end

  private
    def ensure_looked_after
      head :not_found if @person.signs_in?
    end
end
