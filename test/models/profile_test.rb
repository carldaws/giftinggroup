require "test_helper"

class ProfileTest < ActiveSupport::TestCase
  test "a dependant's profile lists their guardians and who else could look after them" do
    profile = Profile.new(users(:dan), viewer: users(:alice))

    assert_not profile.yours?
    assert profile.several_guardians?
    assert profile.you?(guardianships(:alice_looks_after_dan))
    assert_equal [ users(:carol) ], profile.possible_guardians
  end

  test "the name shown is the saved one, not one that failed to save" do
    saved = users(:dan).name
    users(:dan).name = ""

    assert_equal saved, Profile.new(users(:dan), viewer: users(:alice)).saved_name
  end
end
