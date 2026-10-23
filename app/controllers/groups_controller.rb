class GroupsController < ApplicationController
  def index
    @groups = Current.user.groups.order(:name)
  end
end
