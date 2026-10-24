require "test_helper"

class GuardiansTest < ActionDispatch::IntegrationTest
  test "the details page shows who looks after someone, and offers people from their groups" do
    sign_in_as users(:alice)

    get edit_person_profile_path(users(:dan))

    assert_select "#guardians .row-title", text: users(:bob).name
    assert_select "#guardians select option[value=?]", users(:carol).id.to_s
    assert_select "#guardians select option[value=?]", users(:erin).id.to_s, count: 0
    assert_select "#guardians select option[value=?]", users(:bob).id.to_s, count: 0
  end

  test "adding someone else to look after them" do
    sign_in_as users(:alice)

    post person_guardianships_path(users(:dan)), params: { guardianship: { guardian_id: users(:carol).id } }

    assert_redirected_to edit_person_profile_path(users(:dan), anchor: "guardians")
    assert users(:carol).reload.looks_after?(users(:dan))
  end

  test "only people with an account who share a group can be added" do
    sign_in_as users(:alice)

    post person_guardianships_path(users(:dan)), params: { guardianship: { guardian_id: users(:erin).id } }

    assert_response :not_found
    assert_not users(:erin).looks_after?(users(:dan))
  end

  test "removing someone, or stepping back yourself, while someone is still looking after them" do
    sign_in_as users(:alice)

    delete person_guardianship_path(users(:dan), guardianships(:bob_looks_after_dan))
    assert_not users(:bob).reload.looks_after?(users(:dan))

    users(:dan).guardianships_as_dependant.create!(guardian: users(:carol))
    delete person_guardianship_path(users(:dan), guardianships(:alice_looks_after_dan))

    assert_redirected_to person_path(users(:dan))
    assert_not users(:alice).reload.looks_after?(users(:dan))
  end

  test "the last person looking after someone can't be removed" do
    guardianships(:bob_looks_after_dan).destroy!
    sign_in_as users(:alice)

    delete person_guardianship_path(users(:dan), guardianships(:alice_looks_after_dan))

    assert users(:alice).reload.looks_after?(users(:dan))
  end

  test "only people who look after someone can change who does" do
    sign_in_as users(:carol)

    post person_guardianships_path(users(:dan)), params: { guardianship: { guardian_id: users(:carol).id } }

    assert_response :forbidden
    assert_not users(:carol).looks_after?(users(:dan))
  end

  test "people with their own account aren't looked after" do
    sign_in_as users(:alice)

    get edit_person_profile_path(users(:alice))
    assert_select "#guardians", count: 0

    post person_guardianships_path(users(:alice)), params: { guardianship: { guardian_id: users(:bob).id } }
    assert_response :not_found
  end
end
