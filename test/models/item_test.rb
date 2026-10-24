require "test_helper"

class ItemTest < ActiveSupport::TestCase
  test "a name or a link is enough" do
    assert users(:alice).items.build(name: "Walking boots").valid?
    assert users(:alice).items.build(url: "https://www.uniqlo.com/uk/en/products/E486177-000").valid?
  end

  test "an item needs a name or a link" do
    item = users(:alice).items.build(name: "  ", url: "")

    assert_not item.valid?
    assert item.errors.of_kind?(:base, :name_or_link)
    assert_raises(ActiveRecord::StatementInvalid) { item.save!(validate: false) }
  end

  test "an item with only a link is called after its shop" do
    item = users(:alice).items.build(url: "https://www.uniqlo.com/uk/en/products/E486177-000")

    assert_equal I18n.t("items.something_from", shop: "uniqlo.com"), item.title
  end

  test "the owner never sees suggestions on their own list" do
    assert_not_includes Item.visible_to(users(:alice)), items(:scarf_gloves_suggestion)
  end

  test "the owner sees their own items" do
    assert_includes Item.visible_to(users(:alice)), items(:scarf)
  end

  test "everyone else in a group with the owner sees suggestions" do
    assert_includes Item.visible_to(users(:carol)), items(:scarf_gloves_suggestion)
  end

  test "guardians see items and suggestions on their dependant's list" do
    suggestion = users(:dan).items.create!(name: "Dinosaur book", suggested_by: users(:carol))

    assert_includes Item.visible_to(users(:alice)), items(:lego)
    assert_includes Item.visible_to(users(:alice)), suggestion
  end

  test "people who share no group with the owner don't see their items" do
    assert_not_includes Item.visible_to(users(:erin)), items(:scarf)
  end

  test "a list is seen in every group its owner is in" do
    assert_includes Item.visible_to(users(:erin)), items(:books)
    assert_includes Item.visible_to(users(:bob)), items(:books)
  end

  test "the owner can't make a suggestion on their own list" do
    item = users(:alice).items.build(name: "Gloves", suggested_by: users(:alice))

    assert_not item.valid?
    assert item.errors.of_kind?(:suggested_by, :owns_the_list)
  end

  test "guardians add items directly rather than suggesting them" do
    item = users(:dan).items.build(name: "Kite", suggested_by: users(:alice))

    assert_not item.valid?
  end

  test "people who can't see the list can't make suggestions on it" do
    item = users(:alice).items.build(name: "Gloves", suggested_by: users(:erin))

    assert_not item.valid?
    assert item.errors.of_kind?(:suggested_by, :cannot_see_the_list)
  end

  test "who can edit an item" do
    assert items(:scarf).editable_by?(users(:alice))
    assert_not items(:scarf).editable_by?(users(:bob))
    assert items(:lego).editable_by?(users(:bob))
  end

  test "only the suggester can edit a suggestion" do
    assert items(:scarf_gloves_suggestion).editable_by?(users(:bob))
    assert_not items(:scarf_gloves_suggestion).editable_by?(users(:carol))
    assert_not items(:scarf_gloves_suggestion).editable_by?(users(:alice))
  end

  test "an empty quantity means as many as you like" do
    assert items(:books).unlimited?
    assert_not items(:books).fully_reserved?
  end

  test "an item is fully reserved once its quantity is taken" do
    assert items(:scarf).fully_reserved?
    assert_not items(:socks).fully_reserved?
  end

  test "receiving" do
    items(:scarf).receive
    assert items(:scarf).received?
    assert_not_includes Item.wanted, items(:scarf)

    items(:scarf).unreceive
    assert_not items(:scarf).received?
  end

  test "links must be web addresses" do
    [ "javascript:alert(1)", "https://", "https://exa mple.com", "ftp://example.com/file", "https://example.com\njavascript:alert(1)" ].each do |url|
      items(:scarf).url = url

      assert_not items(:scarf).valid?, url
    end
  end

  test "web addresses are fine" do
    items(:scarf).url = "https://www.example.com/scarves?colour=green"

    assert items(:scarf).valid?
  end

  test "quantity must be positive" do
    items(:scarf).quantity = 0

    assert_not items(:scarf).valid?
  end

  test "photos must be images" do
    items(:scarf).photos.attach(io: StringIO.new("not an image"), filename: "notes.txt", content_type: "text/plain")

    assert_not items(:scarf).valid?
    assert items(:scarf).errors.of_kind?(:photos, :not_an_image)
  end

  test "photos" do
    items(:scarf).photos.attach(io: file_fixture("photo.png").open, filename: "photo.png")

    assert items(:scarf).valid?
  end

  test "photos are resized for the list and for viewing" do
    items(:scarf).photos.attach(io: file_fixture("photo.png").open, filename: "photo.png")
    photo = items(:scarf).photos.first

    %i[ thumb large ].each do |size|
      assert_predicate photo.variant(size).processed.image.blob, :persisted?
    end
  end

  test "no more than six photos" do
    7.times { items(:scarf).photos.attach(io: file_fixture("photo.png").open, filename: "photo.png") }

    assert_not items(:scarf).valid?
    assert items(:scarf).errors.of_kind?(:photos, :too_many)
  end
end
