class Groups::Memberships::MessagesController < ApplicationController
  include GroupScoped

  before_action :set_membership
  after_action :mark_read, only: :index

  def index
    @message = Message.new
  end

  def create
    @message = @membership.messages_about.new(message_params.merge(author: Current.user))

    if @message.save
      redirect_to group_membership_messages_path(@group, @membership)
    else
      render :index, status: :unprocessable_content
    end
  end

  private
    def set_membership
      @membership = @group.memberships.with_chat_visible_to(Current.user).find(params[:membership_id])
    end

    def mark_read
      @membership.mark_read_by(Current.user)
    end

    def message_params
      params.expect(message: [ :body ])
    end
end
