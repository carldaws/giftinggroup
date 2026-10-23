require "test_helper"

class ListTest < ActiveSupport::TestCase
  test "members see lists shared with their groups" do
    assert_includes List.visible_to(users(:bob)), lists(:carol_birthday)
  end

  test "lists aren't visible outside the groups they're shared with" do
    assert_not_includes List.visible_to(users(:erin)), lists(:carol_birthday)
  end

  test "owners see their own lists" do
    assert_includes List.visible_to(users(:erin)), lists(:erin_christmas)
  end

  test "guardians see their dependant's lists even when not shared with them" do
    lists(:dan_christmas).shares.destroy_all

    assert_includes List.visible_to(users(:alice)), lists(:dan_christmas)
  end

  test "owners and guardians can edit a list" do
    assert lists(:alice_christmas).editable_by?(users(:alice))
    assert lists(:dan_christmas).editable_by?(users(:bob))
  end

  test "other members can't edit a list" do
    assert_not lists(:alice_christmas).editable_by?(users(:bob))
    assert_not lists(:dan_christmas).editable_by?(users(:carol))
  end
end
