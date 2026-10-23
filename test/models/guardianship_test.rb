require "test_helper"

class GuardianshipTest < ActiveSupport::TestCase
  test "people who sign in look after themselves" do
    guardianship = Guardianship.new(guardian: users(:alice), dependant: users(:bob))

    assert_not guardianship.valid?
    assert guardianship.errors.of_kind?(:dependant, :signs_in)
  end

  test "nobody is their own guardian" do
    guardianship = Guardianship.new(guardian: users(:dan), dependant: users(:dan))

    assert_not guardianship.valid?
    assert guardianship.errors.of_kind?(:dependant, :is_the_guardian)
  end
end
