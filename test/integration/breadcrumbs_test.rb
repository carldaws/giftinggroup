require "test_helper"

class BreadcrumbsTest < ActionDispatch::IntegrationTest
  test "signed-in pages trail back home and end with the current page" do
    sign_in_as users(:bob)

    get group_path(groups(:hollies))

    assert_select "body > nav a[href=?]", root_path
    assert_select "body > nav [aria-current=page]", text: groups(:hollies).name
  end

  test "signed-out pages have no breadcrumbs" do
    get new_session_path

    assert_select "body > nav", count: 0
  end
end
