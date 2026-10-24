require "test_helper"

class LinkPreviewsTest < ActionDispatch::IntegrationTest
  test "a link that can't be fetched fills in nothing" do
    sign_in_as users(:alice)

    post link_preview_path, params: { url: "http://127.0.0.1/admin" }, as: :json

    assert_response :success
    assert_empty response.parsed_body
  end

  test "only people who are signed in can look up links" do
    post link_preview_path, params: { url: "https://shop.example/" }, as: :json

    assert_redirected_to new_session_path
  end

  test "a photo fetched from a link can be attached by whoever fetched it" do
    photo = photo_blob
    sign_in_as users(:alice)

    post person_items_path(users(:alice)), params: { item: { name: "Walking boots", photos: [ link_photo_id(photo, fetched_for: users(:alice)) ] } }

    assert_equal [ photo ], Item.find_by!(name: "Walking boots").photos.blobs
  end

  test "nobody can attach a photo fetched for someone else, an ordinary photo reference, or a made-up one" do
    photo = photo_blob
    sign_in_as users(:alice)

    post person_items_path(users(:alice)),
      params: { item: { name: "Walking boots", photos: [ link_photo_id(photo, fetched_for: users(:bob)), photo.signed_id, "made-up" ] } }

    assert_not Item.find_by!(name: "Walking boots").photos.attached?
  end

  test "a photo reference that's no good doesn't remove the photos an item already has" do
    items(:scarf).photos.attach(io: file_fixture("photo.png").open, filename: "photo.png")
    sign_in_as users(:alice)

    patch item_path(items(:scarf)), params: { item: { name: items(:scarf).name, photos: [ "made-up" ] } }

    assert_equal 1, items(:scarf).reload.photos.count
  end

  test "the item form offers to fill in from a link" do
    sign_in_as users(:alice)

    get new_person_item_path(users(:alice))

    assert_select "form[data-link-preview-endpoint-value=?]", link_preview_path
    assert_select "input[data-link-preview-target=url]"
  end

  private
    def photo_blob
      ActiveStorage::Blob.create_and_upload!(io: file_fixture("photo.png").open, filename: "photo.png", content_type: "image/png")
    end

    def link_photo_id(blob, fetched_for:)
      blob.signed_id(purpose: LinkPreview.photo_purpose(fetched_for), expires_in: 6.hours)
    end
end
