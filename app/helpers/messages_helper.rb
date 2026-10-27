module MessagesHelper
  def unread_chat_title(chat)
    if chat.about_someone?
      t("messages.unread.about", name: chat.subject.user.name)
    else
      t("messages.unread.everyone", group: chat.group.name)
    end
  end

  def chat_anchor(unread_count)
    unread_count.positive? ? "new" : "latest"
  end

  def sent_ago(time)
    if time > 1.minute.ago
      t("messages.just_now")
    else
      t("messages.ago", time: time_ago_in_words(time))
    end
  end
end
