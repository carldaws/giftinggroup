module MessagesHelper
  def sent_ago(time)
    if time > 1.minute.ago
      t("messages.just_now")
    else
      t("messages.ago", time: time_ago_in_words(time))
    end
  end
end
