require "test_helper"

class FooterTest < ActionDispatch::IntegrationTest
  test "the footer links to the code and its author, and greets the season" do
    travel_to Time.zone.local(2026, 10, 31, 12) do
      get new_session_path
    end

    assert_select "footer a[href=?]", "https://github.com/carldaws/giftinglists"
    assert_select "footer a[href=?]", "https://github.com/carldaws"
    assert_select "footer", text: /#{I18n.t("seasonal_greetings.halloween")}/
  end
end
