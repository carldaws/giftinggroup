require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "avatars show the person's name on hover" do
    render html: avatar_tag(users(:alice))

    assert_select ".avatar-tooltip", text: users(:alice).name
  end

  test "avatars can leave the name out" do
    render html: avatar_tag(users(:alice), tooltip: false)

    assert_select ".avatar-tooltip", count: 0
  end
end
