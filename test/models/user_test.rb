require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "email addresses are normalised" do
    typed = " #{users(:alice).email_address.upcase} "

    assert_equal users(:alice).email_address, User.new(email_address: typed).email_address
  end

  test "a blank email address means no email address" do
    assert_nil User.new(email_address: " ").email_address
  end

  test "people without an email address don't sign in" do
    assert users(:alice).signs_in?
    assert_not users(:dan).signs_in?
  end

  test "many people can have no email address" do
    assert User.create!(name: "Fern").persisted?
  end

  test "email addresses are unique" do
    assert_not User.new(name: "Another Alice", email_address: users(:alice).email_address).valid?
  end

  test "people look after themselves and their dependants" do
    assert users(:alice).looks_after?(users(:alice))
    assert users(:alice).looks_after?(users(:dan))
    assert_not users(:alice).looks_after?(users(:bob))
  end

  test "deleting someone deletes their suggestions rather than revealing them to the list owner" do
    suggestion = items(:scarf_gloves_suggestion)
    users(:bob).destroy!

    assert_not Item.exists?(suggestion.id)
  end

  test "deleting someone deletes what they wrote" do
    message = messages(:about_alice)
    users(:bob).destroy!

    assert_not Message.exists?(message.id)
  end
end
