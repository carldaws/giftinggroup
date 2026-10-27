class GroupsController < ApplicationController
  before_action :set_group, only: %i[ show edit update ]

  def index
    @dashboard = Dashboard.new(Current.user)
  end

  def show
  end

  def new
    @group = Group.new
  end

  def create
    @group = Current.user.start_group(group_params)

    if @group.persisted?
      redirect_to edit_group_holidays_path(@group, welcome: 1)
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @group.update(group_params)
      redirect_to @group, notice: t(".renamed")
    else
      render :edit, status: :unprocessable_content
    end
  end

  private
    def set_group
      @group = Current.user.groups.find(params[:id])
    end

    def group_params
      params.expect(group: [ :name ])
    end
end
