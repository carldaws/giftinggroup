class Groups::DependantsController < ApplicationController
  include GroupScoped

  before_action :set_existing_dependants

  def new
    @dependant = User.new
  end

  def create
    @dependant = @group.add_dependant(params.expect(user: [ :name ]), guardian: Current.user)

    if @dependant.persisted?
      redirect_to @group, notice: t(".added", name: @dependant.name)
    else
      render :new, status: :unprocessable_content
    end
  end

  private
    def set_existing_dependants
      @existing_dependants = Current.user.dependants_outside(@group).by_name.to_a
    end
end
