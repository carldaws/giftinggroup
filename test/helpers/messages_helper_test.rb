require "test_helper"

class MessagesHelperTest < ActionView::TestCase
  test "a message from the last minute was sent just now" do
    assert_equal I18n.t("messages.just_now"), sent_ago(20.seconds.ago)
  end

  test "older messages say how long ago they were sent" do
    assert_equal I18n.t("messages.ago", time: time_ago_in_words(2.hours.ago)), sent_ago(2.hours.ago)
  end
end
