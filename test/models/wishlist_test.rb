require "test_helper"

class WishlistTest < ActiveSupport::TestCase
  test "your own list hides surprises and can't show them" do
    wishlist = Wishlist.new(users(:alice), viewer: users(:alice), surprises_shown: true)

    assert wishlist.yours?
    assert wishlist.surprises_hidden?
    assert_not_includes wishlist.cards.map(&:item), items(:scarf_gloves_suggestion)
  end

  test "guardians see surprises on their dependant's list only when they ask" do
    hidden = Wishlist.new(users(:dan), viewer: users(:alice))
    shown = Wishlist.new(users(:dan), viewer: users(:alice), surprises_shown: true)

    assert hidden.surprises_toggle?
    assert hidden.surprises_hidden?
    assert_not shown.surprises_hidden?
  end

  test "everyone else sees surprises and who's getting what" do
    wishlist = Wishlist.new(users(:alice), viewer: users(:carol))

    assert_not wishlist.looked_after?
    assert_not wishlist.surprises_hidden?
    assert_includes wishlist.cards.map(&:item), items(:scarf_gloves_suggestion)
    assert_equal [ reservations(:bob_reserved_scarf) ], wishlist.cards.find { it.item == items(:scarf) }.reservations
  end

  test "little things only shows little things" do
    wishlist = Wishlist.new(users(:alice), viewer: users(:carol), little_only: true)

    assert_equal [ items(:socks) ], wishlist.cards.map(&:item)
  end

  test "given gifts are kept apart from the ones still wanted" do
    reservation = reservations(:carol_bought_lego)
    reservation.update_columns(occasion_id: occasions(:christmas).id)
    occasions(:christmas).update_columns(date: 1.day.ago)

    wishlist = Wishlist.new(users(:dan), viewer: users(:carol))

    assert_equal [ items(:lego) ], wishlist.given_cards.map(&:item)
    assert_not_includes wishlist.still_wanted_cards.map(&:item), items(:lego)
  end

  test "cards share who could split with you" do
    kite = users(:dan).items.create!(name: "Kite")

    card = Wishlist.new(users(:dan), viewer: users(:carol)).cards.find { it.item == kite }

    assert_equal 2, card.split_limit
  end
end
