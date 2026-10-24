require "test_helper"

class ListsTest < ActionDispatch::IntegrationTest
  test "your own list never shows who's getting what, or what's been suggested" do
    sign_in_as users(:alice)

    get person_path(users(:alice))

    assert_response :success
    assert_select "h3", text: items(:scarf).name
    assert_no_match I18n.t("items.item.status.they_getting", name: users(:bob).name), response.body
    assert_no_match items(:scarf_gloves_suggestion).name, response.body
    assert_select "form[action=?]", item_reservation_path(items(:scarf)), count: 0
  end

  test "your own list looks exactly the same whatever others reserve, buy or suggest" do
    sign_in_as users(:alice)
    get person_path(users(:alice))
    before = page_without_tokens

    items(:socks).reservations.create!(user: users(:carol))
    items(:socks).reservations.create!(user: users(:bob)).buy
    users(:alice).items.create!(name: "Secret idea", suggested_by: users(:carol))
    get person_path(users(:alice))

    assert_equal before, page_without_tokens
  end

  test "trying to reserve your own item gets the same answer whether or not it's taken" do
    sign_in_as users(:alice)

    post item_reservation_path(items(:scarf))
    taken = flash[:alert]

    post item_reservation_path(items(:socks))
    free = flash[:alert]

    assert_equal free, taken
  end

  test "everyone else sees reservations and suggestions" do
    sign_in_as users(:carol)

    get person_path(users(:alice))

    assert_select "li", text: /#{I18n.t("items.item.status.they_getting", name: users(:bob).name)}/
    assert_select "h3", text: items(:scarf_gloves_suggestion).name
  end

  test "on someone else's page, things they love and sizes only show when they've added some" do
    sign_in_as users(:carol)

    get person_path(users(:alice))
    assert_select "#things-i-love"
    assert_select "#sizes"

    get person_path(users(:bob))
    assert_select "#things-i-love", count: 0
    assert_select "#sizes", count: 0
  end

  test "on your own page, things you love and sizes always show, ready to fill in" do
    sign_in_as users(:bob)

    get person_path(users(:bob))

    assert_select "#things-i-love form"
    assert_select "#sizes form"
  end

  test "surprise ideas don't spell out who can't see them" do
    sign_in_as users(:carol)

    get new_person_item_path(users(:dan))
    assert_select "h1", text: I18n.t("people.items.new.suggest_heading", name: users(:dan).name)
    assert_no_match(/can.t see|won.t see/i, response.body)

    get person_path(users(:alice))
    assert_no_match(/can.t see|won.t see/i, response.body)
  end

  test "the list can be filtered to little things" do
    sign_in_as users(:carol)

    get person_path(users(:alice), show: "little")

    assert_select "h3", text: items(:socks).name
    assert_select "h3", text: items(:scarf).name, count: 0
  end

  test "ideas from others sit in the same list, marked as ideas" do
    sign_in_as users(:carol)

    get person_path(users(:alice))

    assert_select "##{dom_id(items(:scarf_gloves_suggestion))} span", text: I18n.t("items.item.idea_from", name: users(:bob).name)
  end

  test "a list you look after starts with surprises hidden, so it can be shared with the person it's for" do
    idea = users(:dan).items.create!(name: "Dinosaur book", suggested_by: users(:carol))
    sign_in_as users(:alice)

    get person_path(users(:dan))

    assert_select "h3", text: items(:lego).name
    assert_no_match idea.name, response.body
    assert_no_match I18n.t("items.item.status.they_bought", name: users(:carol).name), response.body
    assert_select "a[href^=?]", group_membership_messages_path(groups(:hollies), memberships(:dan_in_hollies)), count: 0
    assert_select "a[href=?][aria-label=?]", person_path(users(:dan), surprises: "shown"), I18n.t("people.show.show_surprises")
  end

  test "a list you look after looks the same with surprises hidden whatever others reserve, buy, suggest or say" do
    sign_in_as users(:alice)
    get person_path(users(:dan))
    before = page_without_tokens

    reservations(:carol_bought_lego).destroy!
    items(:lego).update!(released_by_name: users(:carol).name)
    items(:lego).reservations.create!(user: users(:bob)).buy
    users(:dan).items.create!(name: "Secret idea", suggested_by: users(:carol))
    Message.create!(subject: memberships(:dan_in_hollies), author: users(:bob), body: messages(:about_dan).body)
    get person_path(users(:dan))

    assert_equal before, page_without_tokens
  end

  test "guardians can show the surprises on the list they look after" do
    sign_in_as users(:alice)

    get person_path(users(:dan), surprises: "shown")

    assert_select "li", text: /#{I18n.t("items.item.status.they_bought", name: users(:carol).name)}/
    assert_select "a[href^=?]", group_membership_messages_path(groups(:hollies), memberships(:dan_in_hollies))
    assert_select "a[href=?][aria-label=?]", person_path(users(:dan)), I18n.t("people.show.hide_surprises")
  end

  test "surprises stay hidden on your own list" do
    sign_in_as users(:alice)

    get person_path(users(:alice), surprises: "shown")

    assert_no_match items(:scarf_gloves_suggestion).name, response.body
    assert_no_match I18n.t("items.item.status.they_getting", name: users(:bob).name), response.body
    assert_select "a[aria-label=?]", I18n.t("people.show.show_surprises"), count: 0
    assert_select "a[aria-label=?]", I18n.t("people.show.hide_surprises"), count: 0
  end

  test "asking to show surprises changes nothing for people who don't look after the list" do
    sign_in_as users(:carol)
    get person_path(users(:alice))
    before = page_without_tokens

    get person_path(users(:alice), surprises: "shown")

    assert_equal before, page_without_tokens.gsub("surprises=shown", "")
  end

  test "showing surprises carries on across the list's tabs" do
    sign_in_as users(:alice)

    get person_path(users(:dan), show: "little", surprises: "shown")

    assert_select "a[href=?]", person_path(users(:dan), show: "little", surprises: "shown", anchor: "list")
    assert_select "a[href=?]", person_path(users(:dan), surprises: "shown", anchor: "list")
    assert_select "a[href=?][aria-label=?]", person_path(users(:dan), show: "little"), I18n.t("people.show.hide_surprises")
  end

  test "people outside your groups can't see your list" do
    sign_in_as users(:erin)

    get person_path(users(:alice))

    assert_response :not_found
  end

  test "adding to your own list" do
    sign_in_as users(:alice)

    post person_items_path(users(:alice)), params: { item: { name: "Walking boots", little: "0" } }

    item = users(:alice).items.last
    assert_redirected_to person_path(users(:alice))
    assert_not item.suggestion?
  end

  test "adding just a link" do
    sign_in_as users(:alice)

    post person_items_path(users(:alice)), params: { item: { name: "", url: "https://www.uniqlo.com/uk/en/products/E486177-000" } }
    follow_redirect!

    assert_select "h3", text: I18n.t("items.something_from", shop: "uniqlo.com")
  end

  test "adding nothing at all asks for a name or a link" do
    sign_in_as users(:alice)

    assert_no_difference -> { Item.count } do
      post person_items_path(users(:alice)), params: { item: { name: "", url: "" } }
    end

    assert_response :unprocessable_content
    assert_match I18n.t("activerecord.errors.messages.name_or_link"), response.body
  end

  test "a name can be taken off an item that has a link, but not both" do
    items(:scarf).update!(url: "https://www.example.com/scarf")
    sign_in_as users(:alice)

    patch item_path(items(:scarf)), params: { item: { name: "", url: "" } }

    assert_response :unprocessable_content
    assert_select "h1", text: items(:scarf).name

    patch item_path(items(:scarf)), params: { item: { name: "" } }

    assert_nil items(:scarf).reload.name
    assert_equal I18n.t("items.something_from", shop: "example.com"), items(:scarf).title
  end

  test "adding a photo with an item, and keeping it when the item is edited" do
    sign_in_as users(:alice)
    post person_items_path(users(:alice)), params: { item: { name: "Walking boots", photos: [ fixture_file_upload("photo.png", "image/png") ] } }
    item = users(:alice).items.last

    patch item_path(item), params: { item: { name: "Brown walking boots" } }

    assert item.reload.photos.attached?
  end

  test "adding a photo saved from a shop's website, even without a file extension" do
    sign_in_as users(:alice)

    post person_items_path(users(:alice)), params: { item: { name: "Fleece jacket", photos: [ fixture_file_upload("saved-photo", "application/octet-stream") ] } }

    assert_equal [ Marcel::MimeType.for(file_fixture("saved-photo")) ], users(:alice).items.last.photos.map(&:content_type)
  end

  test "adding a photo while editing keeps the existing ones" do
    sign_in_as users(:alice)
    post person_items_path(users(:alice)), params: { item: { name: "Walking boots", photos: [ fixture_file_upload("photo.png", "image/png") ] } }
    item = users(:alice).items.last

    patch item_path(item), params: { item: { name: item.name, photos: [ fixture_file_upload("photo.png", "image/png") ] } }

    assert_equal 2, item.reload.photos.count
  end

  test "guardians add things the person asked for straight to their list" do
    sign_in_as users(:bob)

    post person_items_path(users(:dan)), params: { item: { name: "Kite", asked_for: "1" } }

    assert_not users(:dan).items.last.suggestion?
  end

  test "what guardians add is a surprise unless the person asked for it, hidden until they show surprises" do
    sign_in_as users(:bob)

    get new_person_item_path(users(:dan))
    assert_select "input[type=checkbox][name='item[asked_for]']:not([checked])"

    post person_items_path(users(:dan)), params: { item: { name: "Kite", asked_for: "0" } }
    surprise = users(:dan).items.last
    assert surprise.suggestion?
    assert_equal I18n.t("people.items.create.added_quietly"), flash[:notice]

    follow_redirect!
    assert_no_match surprise.name, response.body

    get person_path(users(:dan), surprises: "shown")
    assert_select "h3", text: surprise.name
  end

  test "editing or removing a surprise goes back to the list with surprises showing" do
    surprise = users(:dan).build_item({ name: "Kite" }, by: users(:alice)).tap(&:save!)
    sign_in_as users(:alice)

    get edit_item_path(surprise)
    assert_select "nav a[href=?]", person_path(users(:dan), surprises: "shown")

    patch item_path(surprise), params: { item: { name: "Rainbow kite" } }
    assert_redirected_to person_path(users(:dan), surprises: "shown")

    delete item_path(surprise)
    assert_redirected_to person_path(users(:dan), surprises: "shown")
  end

  test "something that doesn't save keeps its asked-for tick and the usual wording" do
    sign_in_as users(:alice)

    post person_items_path(users(:dan)), params: { item: { name: "", asked_for: "1" } }
    assert_response :unprocessable_content
    assert_select "input[type=checkbox][name='item[asked_for]'][checked]"

    post person_items_path(users(:dan)), params: { item: { name: "", asked_for: "0" } }
    assert_select "input[type=checkbox][name='item[asked_for]']:not([checked])"
    assert_select "h1", text: I18n.t("people.items.new.heading")
  end

  test "guardians can change their mind about whether something was asked for" do
    sign_in_as users(:alice)

    patch item_path(items(:lego)), params: { item: { name: items(:lego).name, asked_for: "0" } }
    assert_equal users(:alice), items(:lego).reload.suggested_by
    assert_redirected_to person_path(users(:dan), surprises: "shown")

    patch item_path(items(:lego)), params: { item: { name: items(:lego).name, asked_for: "1" } }
    assert_not items(:lego).reload.suggestion?
  end

  test "someone else's idea can't be turned into something the person asked for" do
    idea = users(:dan).items.create!(name: "Dinosaur book", suggested_by: users(:carol))
    sign_in_as users(:carol)

    get edit_item_path(idea)
    assert_select "input[name='item[asked_for]']", count: 0

    patch item_path(idea), params: { item: { name: idea.name, asked_for: "1" } }
    assert_equal users(:carol), idea.reload.suggested_by
  end

  test "everyone who looks after them shares the surprises they add" do
    surprise = users(:dan).build_item({ name: "Kite" }, by: users(:alice)).tap(&:save!)
    sign_in_as users(:bob)

    get person_path(users(:dan), surprises: "shown")
    assert_select "h3", text: surprise.name

    patch item_path(surprise), params: { item: { name: surprise.name.upcase, asked_for: "1" } }
    assert_equal surprise.name.upcase, surprise.reload.name
    assert_not surprise.suggestion?
  end

  test "switching something to a surprise doesn't lock out the others who look after them" do
    sign_in_as users(:alice)
    patch item_path(items(:lego)), params: { item: { name: items(:lego).name, asked_for: "0" } }

    sign_in_as users(:bob)
    get edit_item_path(items(:lego))

    assert_response :success
  end

  test "something already received can't be turned into a surprise" do
    items(:lego).receive
    sign_in_as users(:alice)

    patch item_path(items(:lego)), params: { item: { name: items(:lego).name, asked_for: "0" } }

    assert_not items(:lego).reload.suggestion?
  end

  test "the edit page shows whether something was asked for" do
    surprise = users(:dan).build_item({ name: "Kite" }, by: users(:alice)).tap(&:save!)
    sign_in_as users(:alice)

    get edit_item_path(items(:lego))
    assert_select "input[type=checkbox][name='item[asked_for]'][checked]"

    get edit_item_path(surprise)
    assert_select "input[type=checkbox][name='item[asked_for]']:not([checked])"
    assert_select "input[type=hidden][name='item[asked_for]'][value='0']"
  end

  test "edits without the asked-for box leave things as they were" do
    sign_in_as users(:alice)

    patch item_path(items(:lego)), params: { item: { name: "Lego fire engine" } }

    assert_not items(:lego).reload.suggestion?
  end

  test "a surprise stays hidden when the person gets their own account" do
    surprise = users(:dan).build_item({ name: "Kite" }, by: users(:alice)).tap(&:save!)

    users(:dan).update!(email_address: "dan@example.com", password: "a long enough password")

    assert_not_includes Item.visible_to(users(:dan)), surprise
  end

  test "your own list is never a surprise, and other people's always is" do
    sign_in_as users(:alice)

    post person_items_path(users(:alice)), params: { item: { name: "Walking boots", asked_for: "0" } }
    assert_not users(:alice).items.last.suggestion?

    post person_items_path(users(:carol)), params: { item: { name: "Book token", asked_for: "1" } }
    assert users(:carol).items.last.suggestion?
  end

  test "the asked-for choice only appears on lists you look after, not your own or other people's" do
    sign_in_as users(:alice)

    [ users(:alice), users(:carol) ].each do |person|
      get new_person_item_path(person)
      assert_select "input[name='item[asked_for]']", count: 0
    end
  end

  test "adding to someone else's list makes a suggestion they can't see" do
    sign_in_as users(:carol)

    post person_items_path(users(:alice)), params: { item: { name: "Hiking poles" } }

    assert_equal users(:carol), users(:alice).items.last.suggested_by
  end

  test "reserving, buying and letting go" do
    sign_in_as users(:carol)

    post item_reservation_path(items(:socks))
    assert items(:socks).reservations.exists?(user: users(:carol))

    post item_purchase_path(items(:socks))
    assert items(:socks).reservations.find_by(user: users(:carol)).bought?

    delete item_purchase_path(items(:socks))
    assert_not items(:socks).reservations.find_by(user: users(:carol)).bought?

    delete item_reservation_path(items(:socks))
    assert_not items(:socks).reservations.exists?(user: users(:carol))
  end

  test "an item someone else has taken can't be reserved" do
    sign_in_as users(:carol)

    post item_reservation_path(items(:scarf))

    assert_redirected_to person_path(users(:alice))
    assert_not items(:scarf).reservations.exists?(user: users(:carol))
  end

  test "you can't reserve from your own list" do
    sign_in_as users(:alice)

    post item_reservation_path(items(:socks))

    assert_not items(:socks).reservations.exists?(user: users(:alice))
  end

  test "you can't see or reserve suggestions on your own list" do
    sign_in_as users(:alice)

    post item_reservation_path(items(:scarf_gloves_suggestion))

    assert_response :not_found
  end

  test "only the owner, their guardians, or a suggestion's author can edit" do
    sign_in_as users(:bob)

    get edit_item_path(items(:scarf))
    assert_response :forbidden

    get edit_item_path(items(:scarf_gloves_suggestion))
    assert_response :success

    get edit_item_path(items(:lego))
    assert_response :success
  end

  test "ticking off something you received" do
    sign_in_as users(:alice)

    post item_receipt_path(items(:scarf))
    assert items(:scarf).reload.received?

    delete item_receipt_path(items(:scarf))
    assert_not items(:scarf).reload.received?
  end

  test "only the owner or their guardians can tick things off" do
    sign_in_as users(:bob)

    post item_receipt_path(items(:scarf))
    assert_response :forbidden

    post item_receipt_path(items(:scarf_gloves_suggestion))
    assert_response :forbidden
  end

  test "removing an item nobody has picked" do
    sign_in_as users(:alice)

    assert_difference -> { Item.count }, -1 do
      delete item_path(items(:socks))
    end
  end

  test "removing an item someone has picked hides it from the owner but not from the buyer" do
    sign_in_as users(:alice)

    assert_no_difference -> { Item.count } do
      delete item_path(items(:scarf))
    end
    get person_path(users(:alice))
    assert_select "h3", text: items(:scarf).name, count: 0

    get edit_item_path(items(:scarf))
    assert_response :forbidden

    delete session_path
    sign_in_as users(:bob)
    get root_path
    assert_select "#shopping-list .row-title", text: items(:scarf).name
    assert_select "#shopping-list", text: /#{I18n.t("groups.shopping_list.removed")}/

    get person_path(users(:alice))
    assert_select "h3", text: items(:scarf).name, count: 0
  end

  test "a removed item is hidden from everyone who didn't pick it" do
    items(:scarf).remove
    sign_in_as users(:carol)

    get person_path(users(:alice))

    assert_select "h3", text: items(:scarf).name, count: 0
  end

  test "a bought item that's taken off the list says so" do
    reservations(:bob_reserved_scarf).buy
    items(:scarf).remove
    sign_in_as users(:bob)

    get root_path

    assert_select "#shopping-list details", text: /#{I18n.t("groups.shopping_list.removed")}/
    assert_select "#shopping-list details form[action=?]", item_reservation_path(items(:scarf))
  end

  test "a removed item is forgotten once the last person lets it go" do
    items(:socks).reserve_for(users(:bob))
    items(:socks).reserve_for(users(:carol))
    items(:socks).remove

    sign_in_as users(:bob)
    assert_no_difference -> { Item.count } do
      delete item_reservation_path(items(:socks))
    end

    delete session_path
    sign_in_as users(:carol)
    assert_difference -> { Item.count }, -1 do
      delete item_reservation_path(items(:socks))
    end
  end

  test "leaving the group forgets a removed item you'd picked" do
    items(:scarf).remove
    sign_in_as users(:bob)

    assert_difference -> { Item.count }, -1 do
      delete group_membership_path(groups(:hollies), memberships(:bob_in_hollies))
    end
  end

  test "letting go of a removed item forgets it" do
    items(:scarf).remove
    sign_in_as users(:bob)

    assert_difference -> { Item.count }, -1 do
      delete item_reservation_path(items(:scarf))
    end
  end

  test "nobody can pick a removed item" do
    items(:scarf).remove
    sign_in_as users(:carol)

    assert_no_difference -> { Reservation.count } do
      post item_reservation_path(items(:scarf))
    end
  end

  test "adding and removing things you love" do
    sign_in_as users(:alice)

    post person_interests_path(users(:alice)), params: { interest: { name: "Allotment" } }
    assert users(:alice).interests.exists?(name: "Allotment")

    delete person_interest_path(users(:alice), interests(:alice_bowie))
    assert_not Interest.exists?(interests(:alice_bowie).id)
  end

  test "adding sizes" do
    sign_in_as users(:bob)

    post person_sizes_path(users(:dan)), params: { size: { label: "Shoes", value: "Kids 12" } }

    assert users(:dan).sizes.exists?(label: "Shoes")
  end

  test "guardians see suggestions on the list they look after" do
    users(:dan).items.create!(name: "Dinosaur book", suggested_by: users(:carol))
    sign_in_as users(:alice)

    get person_path(users(:dan), surprises: "shown")

    assert_select "h3", text: users(:dan).items.last.name
    assert_select "a[href=?]", new_person_item_path(users(:dan)), count: 1
  end

  test "a file that only claims to be a photo is turned away" do
    sign_in_as users(:alice)

    assert_no_difference -> { Item.count } do
      post person_items_path(users(:alice)), params: { item: { name: "Walking boots", photos: [ fixture_file_upload("not-a-photo.png", "image/png") ] } }
    end

    assert_response :unprocessable_content
    assert_select "[data-clear-files-target=input]"
  end

  test "a failed edit with a new photo shows the form again" do
    sign_in_as users(:alice)

    patch item_path(items(:scarf)), params: { item: { name: "", photos: [ fixture_file_upload("photo.png", "image/png") ] } }

    assert_response :unprocessable_content
    assert_not items(:scarf).reload.photos.attached?
  end

  test "editing can't take an item past six photos" do
    sign_in_as users(:alice)
    6.times { items(:scarf).photos.attach(io: file_fixture("photo.png").open, filename: "photo.png") }

    patch item_path(items(:scarf)), params: { item: { name: items(:scarf).name, photos: [ fixture_file_upload("photo.png", "image/png") ] } }

    assert_response :unprocessable_content
    assert_equal 6, items(:scarf).reload.photos.count
  end

  test "only people who can edit an item can change or remove it, or its photos" do
    items(:scarf).photos.attach(io: file_fixture("photo.png").open, filename: "photo.png")
    sign_in_as users(:bob)

    patch item_path(items(:scarf)), params: { item: { name: "Bob's scarf" } }
    assert_response :forbidden

    delete item_path(items(:scarf))
    assert_response :forbidden

    delete item_photo_path(items(:scarf), items(:scarf).photos.first)
    assert_response :forbidden

    delete session_path
    sign_in_as users(:carol)
    delete item_path(items(:scarf_gloves_suggestion))
    assert_response :forbidden
  end

  test "you can't add to the list of someone you don't share a group with" do
    sign_in_as users(:erin)

    post person_items_path(users(:alice)), params: { item: { name: "Something" } }
    assert_response :not_found

    post person_interests_path(users(:alice)), params: { interest: { name: "Something" } }
    assert_response :not_found
  end

  test "received items can't be reserved" do
    items(:socks).receive
    sign_in_as users(:carol)

    post item_reservation_path(items(:socks))

    assert_not items(:socks).reservations.exists?(user: users(:carol))
  end

  test "reserving twice is harmless" do
    sign_in_as users(:carol)

    post item_reservation_path(items(:socks))
    post item_reservation_path(items(:socks))

    assert_redirected_to person_path(users(:alice))
    assert_equal 1, items(:socks).reservations.where(user: users(:carol)).count
  end

  test "other people can't change your things you love or sizes" do
    sign_in_as users(:bob)

    post person_interests_path(users(:alice)), params: { interest: { name: "Golf" } }
    assert_response :forbidden

    delete person_size_path(users(:alice), sizes(:alice_shoes))
    assert_response :forbidden
  end
end
