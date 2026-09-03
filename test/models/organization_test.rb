require "test_helper"

class OrganizationTest < ActiveSupport::TestCase
  test "fixtures are loaded" do
    assert_equal 3, Organization.count
    assert_equal 10, User.count
  end
end