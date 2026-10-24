require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "avatars show the person's name on hover" do
    render html: avatar_tag(users(:alice))

    assert_select ".tooltip", text: users(:alice).name
  end

  test "avatars show initials, or the character someone chose" do
    render html: avatar_tag(users(:alice))
    assert_select "img", count: 0
    assert_includes rendered, avatar_initials(users(:alice).name)

    users(:alice).avatar_character = User::AVATAR_CHARACTERS.first
    render html: avatar_tag(users(:alice))
    assert_select "img[src*=?]", User::AVATAR_CHARACTERS.first
  end

  test "avatars can leave the name out" do
    render html: avatar_tag(users(:alice), tooltip: false)

    assert_select ".tooltip", count: 0
  end
end
