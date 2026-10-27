class Message::Chat
  def initialize(messages, viewer:)
    @messages, @viewer = messages, viewer
  end

  def messages
    @messages.includes(:author).chronologically
  end

  def first_unread
    @first_unread ||= @messages.unread_by(@viewer).chronologically.first
  end
end
