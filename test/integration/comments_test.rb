require "test_helper"

class CommentsTest < ActionDispatch::IntegrationTest
  test "people can comment on a surprise idea" do
    sign_in_as users(:carol)

    post item_comments_path(items(:scarf_gloves_suggestion)), params: { comment: { body: "She already has some" } }
    follow_redirect!

    assert_select "##{dom_id(items(:scarf_gloves_suggestion))} li", text: /#{items(:scarf_gloves_suggestion).comments.last.body}/
  end

  test "the person whose list it is never sees the comments, or the idea" do
    sign_in_as users(:alice)
    get person_path(users(:alice))
    before = page_without_tokens

    items(:scarf_gloves_suggestion).comments.create!(author: users(:carol), body: "She already has some")
    get person_path(users(:alice))

    assert_equal before, page_without_tokens

    post item_comments_path(items(:scarf_gloves_suggestion)), params: { comment: { body: "Peeking" } }
    assert_response :not_found
  end

  test "only surprise ideas can be commented on" do
    sign_in_as users(:carol)

    get person_path(users(:alice))
    assert_select "##{dom_id(items(:scarf))} form[action=?]", item_comments_path(items(:scarf)), count: 0

    post item_comments_path(items(:scarf)), params: { comment: { body: "Hello" } }
    assert_empty items(:scarf).comments
  end

  test "people outside the group can't comment" do
    sign_in_as users(:erin)

    post item_comments_path(items(:scarf_gloves_suggestion)), params: { comment: { body: "Hello" } }

    assert_response :not_found
  end

  test "people can delete their own comments, and only their own" do
    mine = items(:scarf_gloves_suggestion).comments.create!(author: users(:carol), body: "Already has some")
    theirs = items(:scarf_gloves_suggestion).comments.create!(author: users(:bob), body: "Got them anyway")
    sign_in_as users(:carol)

    delete item_comment_path(items(:scarf_gloves_suggestion), theirs)
    assert_response :not_found

    delete item_comment_path(items(:scarf_gloves_suggestion), mine)
    assert_equal [ theirs ], items(:scarf_gloves_suggestion).comments.reload
  end

  test "comments stay hidden with the rest of the surprises on a list you look after" do
    idea = users(:dan).items.create!(name: "Dinosaur book", suggested_by: users(:carol))
    idea.comments.create!(author: users(:carol), body: "He loves the T. rex ones")
    sign_in_as users(:alice)

    get person_path(users(:dan))
    assert_no_match idea.comments.last.body, response.body

    get person_path(users(:dan), surprises: "shown")
    assert_match idea.comments.last.body, response.body
  end

  test "comments stay, under their name, when someone deletes their account" do
    comment = items(:scarf_gloves_suggestion).comments.create!(author: users(:carol), body: "Already has some")

    users(:carol).delete_account

    assert_equal users(:carol).name, comment.reload.author_name
    assert_nil comment.author
  end
end
