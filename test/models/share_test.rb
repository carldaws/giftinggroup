require "test_helper"

class ShareTest < ActiveSupport::TestCase
  setup do
    @kite = users(:dan).items.create!(name: "Kite")
    @split = @kite.reserve_for(users(:alice), split_with: 2)
  end

  test "you can split with anyone else who can see the item and has their own account" do
    assert_equal [ users(:bob), users(:carol) ], User.who_can_split_gifts_to(users(:dan), with: users(:alice)).by_name
  end

  test "guardians can split even when they're not in a group with the person" do
    groups(:ivies).add(users(:dan))
    groups(:hollies).memberships.find_by!(user: users(:dan)).destroy

    assert_includes User.who_can_split_gifts_to(users(:dan), with: users(:carol)), users(:alice)
  end

  test "people outside the owner's groups can't split" do
    assert_not_includes User.who_can_split_gifts_to(users(:alice), with: users(:bob)), users(:erin)
  end

  test "a split can't ask for more people than can join it" do
    reservation = items(:socks).reservations.build(user: users(:bob), split_with: 2)

    assert_not reservation.valid?
    assert reservation.errors.of_kind?(:split_with, :too_many)
  end

  test "a split takes the item like any reservation, however many people join" do
    @split.join(users(:bob))

    reservation = @kite.reservations.build(user: users(:carol))

    assert_not reservation.valid?
    assert reservation.errors.of_kind?(:item, :fully_reserved)
  end

  test "a split waits until everyone has joined" do
    @split.join(users(:bob))

    assert_equal 1, @split.places_left
    assert @split.waiting?

    @split.join(users(:carol))

    assert_not @split.reload.waiting?
  end

  test "nobody else can join once a split is full" do
    @split.join(users(:bob))
    @split.join(users(:carol))
    groups(:hollies).add(erin = users(:erin))

    share = @split.join(erin)

    assert_not share.persisted?
    assert share.errors.of_kind?(:base, :split_full)
  end

  test "the person who started a split can't join it" do
    share = @split.join(users(:alice))

    assert share.errors.of_kind?(:base, :cannot_split_it)
  end

  test "the person it's for can't join" do
    split = items(:socks).reserve_for(users(:bob), split_with: 1)

    share = split.join(users(:alice))

    assert share.errors.of_kind?(:base, :cannot_split_it)
  end

  test "joining twice keeps one share" do
    first = @split.join(users(:bob))

    assert_equal first, @split.join(users(:bob))
    assert_equal 1, @split.shares.count
  end

  test "you can't join a reservation that isn't a split" do
    share = reservations(:bob_reserved_scarf).join(users(:carol))

    assert share.errors.of_kind?(:base, :not_a_split)
  end

  test "you can't join a split for something they no longer want" do
    @kite.receive

    share = @split.join(users(:bob))

    assert share.errors.of_kind?(:base, :no_longer_wanted)
  end

  test "a split can't be bought until it's complete" do
    @split.join(users(:bob))

    @split.buy

    assert @split.errors.of_kind?(:base, :split_incomplete)
    assert_not @split.reload.bought?

    @split.join(users(:carol))
    @split.reload.buy

    assert @split.bought?
  end

  test "you can leave a split until it's bought" do
    share = @split.join(users(:bob))
    @split.join(users(:carol))

    @split.reload.buy

    share.reload.leave
    assert share.errors.of_kind?(:base, :already_bought)
    assert Share.exists?(share.id)

    @split.unbuy
    share.reload.leave
    assert_not Share.exists?(share.id)
  end

  test "letting go of a split takes everyone's shares with it" do
    @split.join(users(:bob))

    @split.destroy

    assert_empty Share.where(reservation: @split)
  end

  test "leaving the group drops your shares on lists you can no longer see" do
    split = items(:books).reserve_for(users(:alice), split_with: 1)
    split.join(users(:bob))

    groups(:hollies).memberships.find_by!(user: users(:bob)).destroy

    assert_empty users(:bob).shares
  end

  test "you can't join a split on something you're already getting" do
    @kite.update!(quantity: 2)
    @kite.reserve_for(users(:bob))

    share = @split.join(users(:bob))

    assert share.errors.of_kind?(:base, :already_getting_it)
  end

  test "a bought split stays bought when someone in it leaves" do
    @split.join(users(:bob))
    @split.join(users(:carol))
    @split.reload.buy

    groups(:hollies).memberships.find_by!(user: users(:carol)).destroy

    assert_not @split.reload.waiting?
    assert_includes users(:alice).shopping_list, @split
  end

  test "someone who stops looking after a person leaves their splits" do
    split = items(:lego).tap { it.reservations.destroy_all }.reserve_for(users(:carol), split_with: 2)
    split.join(users(:alice))
    memberships(:bob_in_hollies).update!(admin: true)
    memberships(:alice_in_hollies).destroy!

    guardianships(:alice_looks_after_dan).release

    assert_empty users(:alice).shares
  end

  test "a split nobody else can fill is noticed" do
    @split.join(users(:bob))
    groups(:hollies).memberships.find_by!(user: users(:carol)).destroy

    assert_not @split.reload.fillable?
  end

  test "joining a split counts as choosing a gift for them" do
    @split.update!(occasion: occasions(:christmas))
    @split.join(users(:bob))

    assert_includes users(:bob).people_chosen_for(occasions(:christmas)), users(:dan)
  end

  test "you can't reserve something you're already splitting" do
    @kite.update!(quantity: 2)
    @split.join(users(:bob))

    reservation = @kite.reservations.build(user: users(:bob))

    assert_not reservation.valid?
    assert reservation.errors.of_kind?(:base, :already_getting_it)
  end

  test "people already getting the item don't count towards a split" do
    @split.destroy!
    @kite.update!(quantity: 2)
    @kite.reserve_for(users(:bob))

    assert_equal [ users(:carol) ], @kite.people_to_split_with(users(:alice)).to_a
    assert_not @kite.reservations.build(user: users(:alice), split_with: 2).valid?
  end

  test "a split nobody left can join isn't fillable" do
    @split.join(users(:bob))
    @kite.update!(quantity: 2)
    @kite.reserve_for(users(:carol))

    assert_not @split.reload.fillable?
  end

  test "when the person who started a bought split leaves, the first to join takes it over" do
    @split.join(users(:bob))
    @split.join(users(:carol))
    @split.reload.buy
    memberships(:carol_in_hollies).update!(admin: true)

    users(:alice).guardianships.destroy_all
    memberships(:alice_in_hollies).destroy!

    @split.reload
    assert_equal users(:bob), @split.user
    assert_equal [ users(:carol) ], @split.sharers
    assert @split.bought?
    assert_includes users(:bob).shopping_list, @split
    assert_includes users(:carol).shopping_list, @split
  end

  test "deleting your account hands your splits to the first person who joined" do
    @split.join(users(:bob))

    users(:alice).delete_account

    assert_equal users(:bob), @split.reload.user
    assert_empty @split.sharers
  end

  test "giving up a split nobody has joined lets the item go" do
    @split.give_up

    assert_not Reservation.exists?(@split.id)
  end
end
