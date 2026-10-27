require "test_helper"

class ItemsHelperTest < ActionView::TestCase
  setup do
    @kite = users(:dan).items.create!(name: "Kite")
    @split = @kite.reserve_for(users(:alice), split_with: 2)
    @split.update!(occasion: occasions(:christmas))
  end

  test "someone who has joined a split is told who they're splitting it with" do
    @split.join(users(:bob))
    Current.session = users(:bob).sessions.create!

    assert_equal I18n.t("items.item.split_status.joined_waiting_for", others: users(:alice).name, occasion: occasions(:christmas).title, count: 1),
      status_for(@split.reload)
  end

  test "a split says which occasion it's for" do
    @split.join(users(:bob))
    @split.join(users(:carol))
    Current.session = users(:carol).sessions.create!

    assert_equal I18n.t("items.item.split_status.getting_for", names: [ users(:alice).name, users(:bob).name, I18n.t("items.item.you") ].to_sentence, occasion: occasions(:christmas).title),
      status_for(@split.reload)
  end

  test "a bought split everyone else has left reads like any other reservation" do
    @split.update!(split_with: 1)
    @split.join(users(:carol))
    @split.reload.buy
    memberships(:carol_in_hollies).destroy!
    Current.session = users(:bob).sessions.create!

    assert_equal I18n.t("items.item.status.they_bought_for", name: users(:alice).name, occasion: occasions(:christmas).title), status_for(@split.reload)
  end
end
