require "test_helper"

class DirectUploadsTest < ActionDispatch::IntegrationTest
  test "files can't be uploaded straight to storage" do
    assert_no_difference -> { ActiveStorage::Blob.count } do
      post rails_direct_uploads_path, params: { blob: { filename: "anything.png", byte_size: 4, checksum: "x", content_type: "image/png" } }, as: :json
    end

    assert_response :not_found
  end
end
