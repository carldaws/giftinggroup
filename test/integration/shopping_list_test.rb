require "test_helper"

class ShoppingListTest < ActionDispatch::IntegrationTest
  test "your shopping list shows what you've said you'll get, and only yours" do
    sign_in_as users(:bob)

    get root_path

    assert_select "#shopping-list a", text: items(:scarf).name
    assert_select "#shopping-list a", text: items(:lego).name, count: 0
  end

  test "there's no shopping list until you've reserved something" do
    sign_in_as users(:erin)

    get root_path

    assert_select "#shopping-list", count: 0
  end

  test "ticking something off as bought takes you back to your list and moves it down" do
    sign_in_as users(:bob)

    post item_purchase_path(items(:scarf)), headers: { "HTTP_REFERER" => root_url }
    assert_redirected_to root_url

    follow_redirect!
    assert_select "#shopping-list details summary", text: I18n.t("groups.shopping_list.bought_count", count: 1)
    assert_select "#shopping-list details li", text: /#{items(:scarf).name}/
  end

  test "putting something back if it didn't arrive" do
    reservations(:bob_reserved_scarf).buy
    sign_in_as users(:bob)

    delete item_purchase_path(items(:scarf)), headers: { "HTTP_REFERER" => root_url }

    assert_redirected_to root_url
    assert_not reservations(:bob_reserved_scarf).reload.bought?
  end

  test "if the person already has it, the list says so and offers to let it go" do
    items(:scarf).receive
    sign_in_as users(:bob)

    get root_path

    assert_select "#shopping-list p", text: I18n.t("groups.shopping_list.already_has", name: users(:alice).name)
    assert_select "#shopping-list form[action=?]", item_reservation_path(items(:scarf))
  end

  test "gifts that have been given drop off the list" do
    reservations(:bob_reserved_scarf).update!(occasion: occasions(:christmas), bought_at: Time.current)

    travel_to occasions(:christmas).date + 1.day do
      sign_in_as users(:bob)
      get root_path

      assert_select "#shopping-list", count: 0
    end
  end

  test "soonest occasion first, then things with no occasion" do
    reservations(:bob_reserved_scarf).update!(occasion: occasions(:christmas))
    kite = users(:dan).items.create!(name: "Kite")
    soon = groups(:hollies).occasions.create!(name: "Bonfire night", date: 3.days.from_now.to_date)
    sock_reservation = items(:socks).reservations.create!(user: users(:bob), occasion: soon)
    kite_reservation = kite.reservations.create!(user: users(:bob))

    assert_equal [ sock_reservation, reservations(:bob_reserved_scarf), kite_reservation ], users(:bob).shopping_list
  end
end
