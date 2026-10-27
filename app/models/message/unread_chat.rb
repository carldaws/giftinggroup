Message::UnreadChat = Data.define(:group, :subject, :messages) do
  def about_someone?
    subject.present?
  end

  def latest
    messages.last
  end
end
