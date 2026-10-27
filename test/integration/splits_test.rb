require "test_helper"

class SplitsTest < ActionDispatch::IntegrationTest
  setup do
    @kite = users(:dan).items.create!(name: "Kite")
  end

  test "you choose how many others to split with, up to everyone who could join" do
    sign_in_as users(:carol)

    get person_path(users(:dan))

    assert_select "##{dom_id(@kite)} summary", text: I18n.t("items.item.split")
    assert_select "##{dom_id(@kite)} select[name='reservation[split_with]'] option", count: 2
  end

  test "there's no split button when nobody else could join" do
    sign_in_as users(:carol)

    get person_path(users(:erin))

    assert_select "##{dom_id(items(:tent))} summary", count: 0
  end

  test "starting a split shows it waiting on your homepage" do
    sign_in_as users(:alice)

    post item_reservation_path(@kite), params: { reservation: { split_with: 2 } }, headers: { "HTTP_REFERER" => root_url }
    follow_redirect!

    occasion = @kite.reservations.sole.occasion
    assert_select "#splits p", text: I18n.t("items.item.split_status.you_waiting_for", count: 2, occasion: occasion.title)
    assert_select "#shopping-list", count: 0
  end

  test "asking for more people than can join is turned down" do
    sign_in_as users(:alice)

    post item_reservation_path(@kite), params: { reservation: { split_with: 3 } }

    assert_not @kite.reservations.exists?
    assert_match I18n.t("activerecord.errors.messages.too_many", count: 2), flash[:alert]
  end

  test "everyone else who can see the item is asked to join, but never the person it's for" do
    split = @kite.reserve_for(users(:bob), split_with: 1)

    sign_in_as users(:carol)
    get root_path
    assert_select "#splits p", text: I18n.t("items.item.split_status.they_waiting_for", name: users(:bob).name, count: 1, occasion: split.occasion.title)

    get person_path(users(:dan))
    assert_select "##{dom_id(@kite)} button", text: I18n.t("items.item.join_split", name: users(:bob).name)
    assert_select "##{dom_id(@kite)} button", text: I18n.t("items.item.reserve"), count: 0
  end

  test "the person it's for sees nothing of a split for them" do
    split = items(:socks).reserve_for(users(:bob), split_with: 1)
    sign_in_as users(:alice)

    get root_path
    assert_select "#splits", count: 0

    post item_split_share_path(split.item, split)
    assert_response :not_found
  end

  test "once everyone joins, it's on everyone's shopping list" do
    split = @kite.reserve_for(users(:alice), split_with: 1)
    sign_in_as users(:bob)

    post item_split_share_path(split.item, split), headers: { "HTTP_REFERER" => root_url }
    follow_redirect!

    assert_select "#splits", count: 0
    assert_select "#shopping-list p", text: I18n.t("items.item.splitting_with", names: users(:alice).name)
    assert_select "#shopping-list li button", text: I18n.t("groups.shopping_list.leave_split")

    delete session_path
    sign_in_as users(:alice)
    get root_path

    assert_select "#shopping-list p", text: I18n.t("items.item.splitting_with", names: users(:bob).name)
    assert_select "#shopping-list li button", text: I18n.t("groups.shopping_list.bought")
  end

  test "leaving a split puts it back to waiting" do
    split = @kite.reserve_for(users(:alice), split_with: 1)
    split.join(users(:carol))
    sign_in_as users(:carol)

    delete item_split_share_path(split.item, split), headers: { "HTTP_REFERER" => root_url }
    follow_redirect!

    assert_select "#splits li button", text: I18n.t("groups.splits.join")
    assert_select "#shopping-list a", text: @kite.name, count: 0
  end

  test "calling off a split frees the item" do
    @kite.reserve_for(users(:alice), split_with: 2).join(users(:bob))
    sign_in_as users(:alice)

    delete item_reservation_path(@kite)

    assert_not @kite.reservations.exists?
    assert_empty users(:bob).shares
  end

  test "ticking off a split that someone just left explains why it can't be bought yet" do
    @kite.reserve_for(users(:alice), split_with: 1)
    sign_in_as users(:alice)

    post item_purchase_path(@kite)

    assert_equal I18n.t("activerecord.errors.messages.split_incomplete"), flash[:alert]
    assert_not @kite.reservations.first.bought?
  end

  test "only the person who started a split ticks it off as bought" do
    @kite.reserve_for(users(:alice), split_with: 1).join(users(:bob))
    sign_in_as users(:bob)

    post item_purchase_path(@kite)

    assert_response :not_found
  end

  test "the person it's for sees nothing of it on their own list and can't touch it" do
    split = items(:socks).reserve_for(users(:bob), split_with: 1)
    split.join(users(:carol))
    sign_in_as users(:alice)

    get person_path(users(:alice))
    assert_select "##{dom_id(items(:socks))} .chip", count: 0
    assert_select "##{dom_id(items(:socks))} form[action='#{item_split_share_path(split.item, split)}']", count: 0

    delete item_split_share_path(split.item, split)
    assert_response :not_found
  end

  test "guardians don't see other people's splits for the person they look after on their homepage" do
    @kite.reserve_for(users(:carol), split_with: 1)
    sign_in_as users(:alice)

    get root_path

    assert_select "#splits", count: 0
  end

  test "the person who started a split hears when there's nobody left to fill it" do
    @kite.reserve_for(users(:carol), split_with: 2).join(users(:alice))
    memberships(:bob_in_hollies).destroy!
    guardianships(:bob_looks_after_dan).destroy!
    sign_in_as users(:carol)

    get root_path

    assert_select "#splits p", text: I18n.t("groups.splits.not_enough_people")
  end
end
