require "application_system_test_case"

class SmokeTest < ApplicationSystemTestCase
  PASSWORD = FixturePasswords::PASSWORD

  setup { queue_adapter.perform_enqueued_jobs = true }

  test "a group sorts out presents, from signing up to chatting about who gets what" do
    alice = "Alice Walker"
    bob = "Bob Smith"
    carol = "Carol Jones"
    rebecca = "Rebecca"
    group = "The Walkers"
    scarf = "Green wool scarf"
    gloves = "Matching gloves"
    book = "Dinosaur book"
    kite = "Rainbow kite"
    hobby = "Hiking"
    plan = "I've got the scarf, could someone do the gloves?"
    reply = "Leave the gloves with me"
    draft = "Half a thought about"
    secret_santa = "Shall we do Secret Santa this year?"
    invite = nil
    join_code = nil
    set_up_link = nil

    using_session(:alice) do
      sign_up alice, "alice@walkers.example"

      click_on t("groups.index.start")
      fill_in t("groups.form.name"), with: group
      click_on t("groups.new.submit")
      click_on t("groups.holidays.edit.continue")
      assert_selector "h1", exact_text: group
      invite = find("[data-share-url-value]")["data-share-url-value"]
      join_code = find("section[aria-labelledby=invite-heading] strong").text

      click_on t("groups.show.add_dependant")
      fill_in t("groups.dependants.form.name"), with: rebecca
      click_on t("groups.dependants.form.submit")
      open_person rebecca
      assert_link t("people.show.edit_details")
      add_item book, asked_for_by: rebecca

      click_on t("people.show.add_item")
      fill_in t("items.form.name"), with: kite
      click_on t("people.items.new.submit")
      assert_text t("people.items.create.added_quietly")
      assert_selector "#list h3", text: book
      assert_no_selector "#list h3", text: kite

      open_your_page alice
      add_item scarf, photo: file_fixture("photo.png")
      within(item_card(scarf)) do
        assert_selector("img") { |photo| photo.evaluate_script("this.complete && this.naturalWidth > 0") }
      end

      within("#things-i-love") do
        fill_in t("people.interests.add_label"), with: hobby
        click_on t("people.interests.add")
        assert_text hobby
      end
    end

    using_session(:bob) do
      visit invite
      click_on t("joins.show.create_account")
      fill_in_registration bob, "bob@walkers.example"
      click_on t("joins.show.join", group:)
      assert_text t("joins.create.joined", group:)

      go_home
      within("section[aria-labelledby=gifts-to-choose-heading]") do
        assert_text alice
        assert_text rebecca
      end

      open_group group
      open_person alice
      assert_text hobby
      within(item_card(scarf)) do
        click_on t("items.item.reserve")
        click_on t("items.item.bought_it")
        assert_text t("items.item.status.you_bought")
      end

      click_on t("people.show.suggest_item")
      fill_in t("items.form.name"), with: gloves
      click_on t("people.items.new.suggest_submit")
      assert_selector "#list h3", text: gloves

      go_home
      open_group group
      open_person rebecca
      assert_no_link t("people.show.edit_details")
      within(item_card(book)) do
        click_on t("items.item.reserve")
        assert_text t("items.item.status.you_getting")
      end

      go_home
      within("#shopping-list") { assert_text book }
      assert_no_selector "section[aria-labelledby=gifts-to-choose-heading]"
    end

    using_session(:carol) do
      sign_up carol, "carol@walkers.example"
      click_on t("groups.index.join")
      fill_in t("joins.new.code"), with: join_code.downcase
      click_on t("joins.new.submit")
      assert_text t("joins.create.joined", group:)

      open_person alice
      open_chat alice, group
      assert_text t("messages.chat.empty")
      fill_in t("groups.memberships.messages.index.label", name: alice), with: draft
    end

    using_session(:bob) do
      go_home
      open_group group
      open_person alice
      open_chat alice, group
      send_message plan, about: alice
    end

    using_session(:carol) do
      assert_text plan
      assert_field t("groups.memberships.messages.index.label", name: alice), with: draft
      send_message reply, about: alice
    end

    using_session(:bob) do
      assert_text reply
      go_home
      open_group group
      open_person carol
      open_chat carol, group
      send_message "Any ideas for Carol?", about: carol

      go_home
      open_group group
      click_on t("groups.show.chat", count: 0)
      assert_text t("groups.messages.index.for_everyone")
      fill_in t("groups.messages.index.label", group:), with: secret_santa
      click_on t("messages.chat.send")
      assert_text secret_santa
    end

    using_session(:alice) do
      go_home
      within("section[aria-labelledby=unread-heading]") { assert_text t("messages.unread.about", name: carol) }
      assert_no_text t("messages.unread.about", name: alice)
      within("section[aria-labelledby=unread-heading]") { click_on t("messages.unread.everyone", group:) }
      assert_text secret_santa
      go_home
      assert_no_text t("messages.unread.everyone", group:)

      open_your_page alice
      within(item_card(scarf)) { assert_no_text bob }
      assert_no_text gloves
      assert_no_selector "a[href*=messages]"

      within(item_card(scarf)) { click_on t("items.item.edit") }
      accept_confirm { click_on t("items.edit.remove") }
      assert_text t("items.destroy.removed", name: scarf)
      assert_no_selector "#list h3", text: scarf

      go_home
      open_group group
      open_person carol
      assert_link t("people.chats.label", name: carol, group:, count: 1)

      go_home
      open_group group
      open_person rebecca
      within(item_card(book)) { assert_no_text t("items.item.status.they_getting", name: bob) }
      click_on t("people.show.show_surprises")
      within(item_card(book)) { assert_text t("items.item.status.they_getting", name: bob) }
      click_on t("people.show.hide_surprises")
      assert_link t("people.show.show_surprises")
      within(item_card(book)) { assert_no_text t("items.item.status.they_getting", name: bob) }

      click_on t("people.show.edit_details")
      select carol, from: t("people.profiles.edit.add_guardian_label", name: rebecca)
      click_on t("people.profiles.edit.add_guardian")
      assert_text t("people.guardianships.create.added", name: carol, dependant: rebecca)

      go_home
      open_group group
      open_member_menu rebecca
      click_on t("groups.membership.set_up_link")
      assert_selector "h1", exact_text: t("groups.memberships.sign_in_links.show.heading", name: rebecca)
      set_up_link = find("[data-share-url-value]")["data-share-url-value"]
    end

    using_session(:rebecca) do
      visit set_up_link
      fill_in t("passwords.edit.email_address"), with: "rebecca@walkers.example"
      fill_in t("passwords.edit.password"), with: PASSWORD
      click_on t("passwords.edit.submit")

      open_your_page rebecca
      within(item_card(book)) { assert_no_text bob }
      assert_no_selector "a[href*=messages]"
    end

    using_session(:alice) do
      open_account_menu
      click_on t("layouts.account_menu.sign_out")
      sign_in "alice@walkers.example"
      assert_selector "#groups-heading"
    end

    using_session(:carol) do
      open_account_menu
      click_on t("layouts.account_menu.your_details")
      click_on t("people.profiles.edit.delete_account")
      fill_in t("account_deletions.new.password"), with: PASSWORD
      click_on t("account_deletions.new.submit")
      assert_text t("account_deletions.create.deleted")
    end

    using_session(:alice) do
      go_home
      assert_no_text t("messages.unread.about", name: carol)
    end

    using_session(:bob) do
      go_home
      open_group group
      open_person alice
      open_chat alice, group
      assert_text t("messages.message.left", name: carol)
      assert_text reply

      go_home
      within("#shopping-list") do
        find("summary", text: t("groups.shopping_list.bought_count", count: 1)).click
        within("li", text: scarf) { assert_text t("groups.shopping_list.removed") }
      end
    end
  end

  private
    def t(...)
      I18n.t!(...)
    end

    def sign_up(name, email_address)
      visit root_path
      assert_selector "h1", exact_text: t("home.show.heading")
      click_on t("home.show.create_account"), match: :first
      fill_in_registration name, email_address
    end

    def fill_in_registration(name, email_address)
      fill_in t("registrations.new.name"), with: name
      fill_in t("registrations.new.email_address"), with: email_address
      fill_in t("registrations.new.password"), with: PASSWORD
      click_on t("registrations.new.submit")
    end

    def sign_in(email_address)
      fill_in t("sessions.new.email_address"), with: email_address
      fill_in t("sessions.new.password"), with: PASSWORD
      click_on t("sessions.new.submit")
    end

    def go_home
      visit root_path
      assert_selector "#groups-heading"
    end

    def open_group(name)
      within("section[aria-labelledby=groups-heading]") { click_on name }
      assert_selector "h1", exact_text: name
    end

    def open_person(name)
      within("section[aria-labelledby=people-heading]") { click_on name }
      assert_selector "h1", exact_text: name
    end

    def open_member_menu(name)
      find(:element, :summary, "aria-label": t("groups.membership.options_for", name:)).click
    end

    def open_your_page(name)
      open_account_menu
      click_on t("layouts.account_menu.your_page")
      assert_selector "h1", exact_text: name
    end

    def open_account_menu
      find(:element, :summary, "aria-label": t("layouts.account_menu.label")).click
    end

    def open_chat(name, group, unread: 0)
      click_on t("people.chats.label", name:, group:, count: unread)
      assert_selector "h1", exact_text: t("groups.memberships.messages.index.heading", name:)
      connect_turbo_cable_stream_sources
    end

    def add_item(name, photo: nil, asked_for_by: nil)
      click_on t("people.show.add_item")
      fill_in t("items.form.name"), with: name
      attach_file t("items.form.photos"), photo if photo.present?
      check t("items.form.asked_for", name: asked_for_by) if asked_for_by.present?
      click_on t("people.items.new.submit")
      assert_selector "#list h3", text: name
    end

    def item_card(name)
      find("#list li.card", text: name)
    end

    def send_message(body, about:)
      fill_in t("groups.memberships.messages.index.label", name: about), with: body
      click_on t("messages.chat.send")
      assert_text body
      assert_field t("groups.memberships.messages.index.label", name: about), with: ""
      connect_turbo_cable_stream_sources
    end
end
