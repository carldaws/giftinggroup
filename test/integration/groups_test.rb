require "test_helper"

class GroupsTest < ActionDispatch::IntegrationTest
  test "starting a group" do
    sign_in_as users(:erin)

    assert_difference -> { Group.count } do
      post groups_path, params: { group: { name: "The Oaks" } }
    end

    group = Group.last
    assert_redirected_to edit_group_holidays_path(group, welcome: 1)
    assert group.admin?(users(:erin))
  end

  test "a group needs a name" do
    sign_in_as users(:erin)

    post groups_path, params: { group: { name: "" } }

    assert_response :unprocessable_content
  end

  test "your groups are listed on the home page" do
    sign_in_as users(:carol)

    get root_path

    assert_select "section[aria-labelledby=groups-heading] .row-title", text: groups(:hollies).name
    assert_select "section[aria-labelledby=groups-heading] .row-title", text: groups(:ivies).name
  end

  test "the group page lists its people and its invite link" do
    sign_in_as users(:bob)

    get group_path(groups(:hollies))

    assert_response :success
    groups(:hollies).members.each { |member| assert_select "li p", text: /#{member.name}/ }
    assert_select "p", text: join_url(groups(:hollies).join_code)
  end

  test "people outside a group can't see it" do
    sign_in_as users(:erin)

    get group_path(groups(:hollies))

    assert_response :not_found
  end

  test "admins can rename a group" do
    sign_in_as users(:alice)

    new_name = "The Holly Bushes"
    patch group_path(groups(:hollies)), params: { group: { name: new_name } }

    assert_redirected_to groups(:hollies)
    assert_equal new_name, groups(:hollies).reload.name
  end

  test "anyone in the group can rename it" do
    sign_in_as users(:bob)
    new_name = "Bob's group"

    patch group_path(groups(:hollies)), params: { group: { name: new_name } }

    assert_equal new_name, groups(:hollies).reload.name
  end

  test "joining with a typed code" do
    sign_in_as users(:erin)

    post joins_path, params: { join_code: groups(:hollies).formatted_join_code.downcase }

    assert_redirected_to groups(:hollies)
    assert_includes groups(:hollies).members, users(:erin)
  end

  test "a wrong code doesn't join anything" do
    sign_in_as users(:erin)

    assert_no_difference -> { Membership.count } do
      post joins_path, params: { join_code: "NOPE-NOPE" }
    end
    assert_redirected_to new_join_path
  end

  test "following an invite link while signed out, then creating an account, comes back to the invite" do
    get join_path(groups(:hollies).join_code)
    assert_response :success
    assert_select "h1", text: groups(:hollies).name

    post registration_path, params: { user: { name: "Fern", email_address: "fern@example.com", password: "a long enough password" } }
    assert_redirected_to join_url(groups(:hollies).join_code)

    assert_difference -> { groups(:hollies).members.count } do
      post joins_path, params: { join_code: groups(:hollies).join_code }
    end
  end

  test "an old invite link says so" do
    get join_path("OLDCODE1")

    assert_select "h1", text: I18n.t("joins.show.not_found_heading")
  end

  test "admins can make a new join code" do
    sign_in_as users(:alice)
    old_code = groups(:hollies).join_code

    patch group_join_code_path(groups(:hollies))

    assert_not_equal old_code, groups(:hollies).reload.join_code
  end

  test "other members can't make a new join code" do
    sign_in_as users(:bob)

    patch group_join_code_path(groups(:hollies))

    assert_response :forbidden
  end

  test "admins can make others admins" do
    sign_in_as users(:alice)

    patch group_membership_path(groups(:hollies), memberships(:bob_in_hollies)), params: { membership: { admin: true } }

    assert memberships(:bob_in_hollies).reload.admin?
  end

  test "other members can't make themselves admins" do
    sign_in_as users(:bob)

    patch group_membership_path(groups(:hollies), memberships(:bob_in_hollies)), params: { membership: { admin: true } }

    assert_response :forbidden
    assert_not memberships(:bob_in_hollies).reload.admin?
  end

  test "admins can remove people" do
    sign_in_as users(:alice)

    delete group_membership_path(groups(:hollies), memberships(:carol_in_hollies))

    assert_redirected_to groups(:hollies)
    assert_not_includes groups(:hollies).members, users(:carol)
  end

  test "other members can't remove people" do
    sign_in_as users(:bob)

    delete group_membership_path(groups(:hollies), memberships(:carol_in_hollies))

    assert_response :forbidden
  end

  test "leaving a group" do
    sign_in_as users(:bob)

    delete group_membership_path(groups(:hollies), memberships(:bob_in_hollies))

    assert_redirected_to root_path
    assert_not_includes groups(:hollies).members, users(:bob)
  end

  test "the last admin can't leave" do
    sign_in_as users(:alice)

    delete group_membership_path(groups(:hollies), memberships(:alice_in_hollies))

    assert_redirected_to groups(:hollies)
    assert_equal I18n.t("activerecord.errors.messages.last_admin"), flash[:alert]
  end

  test "adding someone who doesn't use the app" do
    sign_in_as users(:carol)

    post group_dependants_path(groups(:hollies)), params: { user: { name: "Fern" } }

    assert_redirected_to groups(:hollies)
    assert_includes groups(:hollies).members, users(:carol).dependants.sole
  end

  test "admins can make a sign-in link that lets someone choose a new password" do
    sign_in_as users(:alice)
    get group_membership_sign_in_link_path(groups(:hollies), memberships(:bob_in_hollies))
    assert_response :success
    link = css_select("[data-share-url-value]").first["data-share-url-value"]
    delete session_path

    get link
    assert_response :success

    patch link.delete_suffix("/edit"), params: { user: { email_address: users(:bob).email_address, password: "a brand new password" } }
    assert_redirected_to root_url
    assert users(:bob).reload.authenticate("a brand new password")

    get link
    assert_response :not_found
  end

  test "anyone in the group can make a sign-in link for another adult" do
    sign_in_as users(:bob)

    get group_path(groups(:hollies))
    assert_select "a[href=?]", group_membership_sign_in_link_path(groups(:hollies), memberships(:carol_in_hollies))

    get group_membership_sign_in_link_path(groups(:hollies), memberships(:carol_in_hollies))

    assert_response :success
  end

  test "only guardians can make a set-up link for someone they look after" do
    sign_in_as users(:carol)

    get group_membership_sign_in_link_path(groups(:hollies), memberships(:dan_in_hollies))

    assert_response :forbidden
  end

  test "people outside a group can't make sign-in links for its members" do
    sign_in_as users(:erin)

    get group_membership_sign_in_link_path(groups(:hollies), memberships(:bob_in_hollies))

    assert_response :not_found
  end

  test "guardians can make a set-up link so a dependant gets their own account" do
    sign_in_as users(:bob)
    get group_membership_sign_in_link_path(groups(:hollies), memberships(:dan_in_hollies))
    link = css_select("[data-share-url-value]").first["data-share-url-value"]
    delete session_path

    patch link.delete_suffix("/edit"), params: { user: { email_address: "dan@example.com", password: "a brand new password" } }

    assert_redirected_to root_url
    assert users(:dan).reload.signs_in?
    assert_empty users(:dan).guardians
  end

  test "a password reset can't change someone's email address" do
    original_email_address = users(:bob).email_address

    patch password_path(users(:bob).generate_token_for(:sign_in_link)),
      params: { user: { email_address: "someone-else@example.com", password: "a brand new password" } }

    assert_redirected_to root_url
    assert_equal original_email_address, users(:bob).reload.email_address
  end

  test "setting up an account needs an email address nobody else uses" do
    patch password_path(users(:dan).generate_token_for(:sign_in_link)),
      params: { user: { email_address: users(:alice).email_address, password: "a brand new password" } }

    assert_response :unprocessable_content
    assert_not users(:dan).reload.signs_in?
  end

  test "a tampered sign-in link shows the expired page" do
    get edit_password_path("not-a-real-token")

    assert_response :not_found
    assert_select "h1", text: I18n.t("passwords.expired.heading")
  end

  test "sign-in link pages are never stored" do
    sign_in_as users(:alice)

    get group_membership_sign_in_link_path(groups(:hollies), memberships(:bob_in_hollies))
    assert response.cache_control[:no_store]

    get edit_password_path(users(:bob).generate_token_for(:sign_in_link))
    assert response.cache_control[:no_store]
  end

  test "members can't make set-up links for, or remove, someone else's dependant" do
    sign_in_as users(:carol)

    get group_membership_sign_in_link_path(groups(:hollies), memberships(:dan_in_hollies))
    assert_response :forbidden

    delete group_membership_path(groups(:hollies), memberships(:dan_in_hollies))
    assert_response :forbidden
  end

  test "a membership from another group can't be reached through your group" do
    sign_in_as users(:alice)

    get group_membership_sign_in_link_path(groups(:hollies), memberships(:erin_in_ivies))

    assert_response :not_found
  end

  test "dependants can't be made admins" do
    sign_in_as users(:alice)

    patch group_membership_path(groups(:hollies), memberships(:dan_in_hollies)), params: { membership: { admin: true } }

    assert_not memberships(:dan_in_hollies).reload.admin?
    assert_equal I18n.t("activerecord.errors.messages.dependant_admin"), flash[:alert]
  end
end
