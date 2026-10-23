require "test_helper"

class ApplicationCable::ConnectionTest < ActionCable::Connection::TestCase
  test "connects someone who's signed in" do
    cookies.signed[:session_id] = users(:alice).sessions.create!.id

    connect

    assert_equal users(:alice), connection.current_user
  end

  test "turns away anyone who isn't signed in" do
    assert_reject_connection { connect }
  end
end
