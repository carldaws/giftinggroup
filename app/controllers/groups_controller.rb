class GroupsController < ApplicationController
  before_action :set_group, only: %i[ show edit update ]

  def index
    @groups = Current.user.groups.includes(:members).by_name
  end

  def show
    @overview = Group::Overview.new(@group, viewer: Current.user)
  end

  def new
    @group = Group.new
  end

  def create
    @group = Current.user.start_group(group_params)

    if @group.persisted?
      track_event "group-created"
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
