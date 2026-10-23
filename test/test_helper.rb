ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)

    fixtures :all

    setup { Rails.cache.clear }
  end
end

module SignInHelper
  def sign_in_as(user)
    request_code_for user.email_address
    post session_verification_path, params: { code: MagicLink.find_by(email_address: user.email_address).code }
  end

  def request_code_for(email_address)
    post session_path, params: { magic_link: { email_address: } }
  end
end

class ActionDispatch::IntegrationTest
  include SignInHelper
end
