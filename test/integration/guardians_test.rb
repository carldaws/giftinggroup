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

  test "only people with their own account who share a group can be added" do
    toddler = groups(:hollies).add_dependant({ name: "Toddler" }, guardian: users(:alice))
    sign_in_as users(:alice)

    [ users(:erin), toddler ].each do |someone|
      post person_guardianships_path(users(:dan)), params: { guardianship: { guardian_id: someone.id } }

      assert_response :not_found
      assert_not someone.looks_after?(users(:dan))
    end
  end

  test "removing someone else who looks after them" do
    sign_in_as users(:alice)

    delete person_guardianship_path(users(:dan), guardianships(:bob_looks_after_dan))

    assert_redirected_to edit_person_profile_path(users(:dan), anchor: "guardians")
    assert_not users(:bob).reload.looks_after?(users(:dan))
  end

  test "stepping back yourself while someone else still looks after them" do
    sign_in_as users(:alice)

    delete person_guardianship_path(users(:dan), guardianships(:alice_looks_after_dan))

    assert_redirected_to person_path(users(:dan))
    assert_not users(:alice).reload.looks_after?(users(:dan))
  end

  test "stepping back from someone you'll no longer see takes you home" do
    toddler = groups(:hollies).add_dependant({ name: "Toddler" }, guardian: users(:alice))
    groups(:ivies).join(toddler)
    toddler.reload.guardianships_as_dependant.create!(guardian: users(:erin))
    sign_in_as users(:alice)

    delete person_guardianship_path(toddler, toddler.guardianships_as_dependant.find_by!(guardian: users(:alice)))

    assert_redirected_to root_path
    assert_not toddler.visible_to?(users(:alice))
  end

  test "the last person looking after someone can't be removed, and is told why" do
    guardianships(:bob_looks_after_dan).destroy!
    sign_in_as users(:alice)

    delete person_guardianship_path(users(:dan), guardianships(:alice_looks_after_dan))

    assert_redirected_to edit_person_profile_path(users(:dan), anchor: "guardians")
    assert_equal I18n.t("activerecord.errors.messages.last_guardian"), flash[:alert]
    assert users(:alice).reload.looks_after?(users(:dan))
  end

  test "only people who look after someone can change who does" do
    sign_in_as users(:carol)

    post person_guardianships_path(users(:dan)), params: { guardianship: { guardian_id: users(:carol).id } }
    assert_response :forbidden

    delete person_guardianship_path(users(:dan), guardianships(:bob_looks_after_dan))
    assert_response :forbidden
    assert users(:bob).reload.looks_after?(users(:dan))
  end

  test "a guardianship can only be changed through the person it's about" do
    toddler = groups(:hollies).add_dependant({ name: "Toddler" }, guardian: users(:alice))
    sign_in_as users(:alice)

    delete person_guardianship_path(toddler, guardianships(:bob_looks_after_dan))

    assert_response :not_found
    assert users(:bob).reload.looks_after?(users(:dan))
  end

  test "people with their own account aren't looked after" do
    sign_in_as users(:alice)

    get edit_person_profile_path(users(:alice))
    assert_select "#guardians", count: 0

    post person_guardianships_path(users(:alice)), params: { guardianship: { guardian_id: users(:bob).id } }
    assert_response :not_found
  end
end
