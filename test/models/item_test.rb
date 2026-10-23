require "test_helper"

class ItemTest < ActiveSupport::TestCase
  test "the list owner never sees suggestions on their own list" do
    assert_not_includes Item.visible_to(users(:alice)), items(:scarf_gloves_suggestion)
  end

  test "the list owner sees no suggestions however many groups share their list" do
    lists(:alice_christmas).shares.create!(group: groups(:ivies))
    groups(:ivies).add(users(:alice))

    assert_not_includes Item.visible_to(users(:alice)), items(:scarf_gloves_suggestion)
  end

  test "the list owner sees their own items" do
    assert_includes Item.visible_to(users(:alice)), items(:scarf)
  end

  test "everyone else sees suggestions" do
    assert_includes Item.visible_to(users(:carol)), items(:scarf_gloves_suggestion)
  end

  test "guardians see suggestions on their dependant's list" do
    suggestion = lists(:dan_christmas).items.create!(name: "Dinosaur book", suggested_by: users(:carol))

    assert_includes Item.visible_to(users(:alice)), suggestion
  end

  test "people who can't see the list don't see its items" do
    assert_not_includes Item.visible_to(users(:erin)), items(:scarf)
  end

  test "the list owner can't make a suggestion on their own list" do
    item = lists(:alice_christmas).items.build(name: "Gloves", suggested_by: users(:alice))

    assert_not item.valid?
    assert item.errors.of_kind?(:suggested_by, :owns_the_list)
  end

  test "people who can't see the list can't make suggestions on it" do
    item = lists(:alice_christmas).items.build(name: "Gloves", suggested_by: users(:erin))

    assert_not item.valid?
    assert item.errors.of_kind?(:suggested_by, :cannot_see_the_list)
  end

  test "an empty quantity means as many as you like" do
    assert items(:books).unlimited?
    assert_not items(:scarf).unlimited?
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

  test "no more than six photos" do
    7.times { items(:scarf).photos.attach(io: file_fixture("photo.png").open, filename: "photo.png") }

    assert_not items(:scarf).valid?
    assert items(:scarf).errors.of_kind?(:photos, :too_many)
  end
end
