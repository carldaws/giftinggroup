require "test_helper"

class UserDeletionTest < ActiveSupport::TestCase
  test "deleting an account lets go of what you'd picked, leaving a note for the group" do
    name = users(:carol).name

    users(:carol).delete_account

    assert_empty items(:lego).reservations
    assert_equal name, items(:lego).reload.released_by_name
  end

  test "a gift that was already given counts as received" do
    reservations(:carol_bought_lego).update!(occasion: occasions(:christmas))
    occasions(:christmas).update!(date: 1.week.ago.to_date)

    users(:carol).delete_account

    assert items(:lego).reload.received?
    assert_nil items(:lego).released_by_name
  end

  test "an idea from someone who has since left the group can still be let go" do
    idea = users(:alice).build_item({ name: "Board game" }, by: users(:carol)).tap(&:save!)
    idea.reserve_for(users(:bob))
    memberships(:carol_in_hollies).destroy!

    users(:bob).delete_account

    assert_equal users(:bob).name, idea.reload.released_by_name
  end

  test "picking a released item clears the note" do
    users(:carol).delete_account

    items(:lego).reserve_for(users(:bob))

    assert_nil items(:lego).reload.released_by_name
  end

  test "chat messages stay under the name of someone who's left" do
    name = users(:bob).name

    users(:bob).delete_account

    assert messages(:about_alice).reload.author_left?
    assert_equal name, messages(:about_alice).author_name
  end

  test "someone only you look after is deleted with you" do
    guardianships(:bob_looks_after_dan).destroy!
    dan = users(:dan)

    users(:alice).delete_account

    assert_not User.exists?(dan.id)
  end

  test "someone else still looks after is kept" do
    users(:alice).delete_account

    assert User.exists?(users(:dan).id)
  end

  test "another adult becomes admin when the only admin leaves" do
    users(:carol).delete_account

    assert groups(:ivies).admin?(users(:erin))
  end

  test "a group with nobody else who has an account is deleted" do
    solo = users(:erin).start_group(name: "Just me")

    users(:erin).delete_account

    assert_not Group.exists?(solo.id)
  end

  test "surprise ideas go, unless someone picked them" do
    unpicked = users(:alice).build_item({ name: "Board game" }, by: users(:bob)).tap(&:save!)
    items(:scarf_gloves_suggestion).reserve_for(users(:carol))

    users(:bob).delete_account

    assert_not Item.exists?(unpicked.id)
    assert items(:scarf_gloves_suggestion).reload.removed?
    assert_includes users(:carol).shopping_list.map(&:item), items(:scarf_gloves_suggestion)
  end
end
