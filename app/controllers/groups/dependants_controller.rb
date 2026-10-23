class Groups::DependantsController < ApplicationController
  include GroupScoped

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
end
