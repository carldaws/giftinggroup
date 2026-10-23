ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module FixturePasswords
  PASSWORD = "correct horse battery"

  def password_digest
    BCrypt::Password.create(PASSWORD, cost: BCrypt::Engine::MIN_COST)
  end
end

ActiveRecord::FixtureSet.context_class.include FixturePasswords

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)

    fixtures :all

    setup { Rails.cache.clear }
  end
end

module SignInHelper
  def sign_in_as(user, password: FixturePasswords::PASSWORD, headers: {})
    post session_path, params: { email_address: user.email_address, password: }, headers:
  end
end

class ActionDispatch::IntegrationTest
  include SignInHelper
end
