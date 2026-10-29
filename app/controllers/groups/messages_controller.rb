class Groups::MessagesController < ApplicationController
  include GroupScoped

  after_action :mark_read, only: :index

  def index
    @message = Message.new
  end

  def create
    @message = @group.messages.new(message_params.merge(author: Current.user))

    if @message.save
      track_event "message-sent", chat: "group", group_age: @group.created_at
      redirect_to group_messages_path(@group)
    else
      render :index, status: :unprocessable_content
    end
  end

  private
    def mark_read
      @group.mark_read_by(Current.user)
    end

    def message_params
      params.expect(message: [ :body ])
    end
end
