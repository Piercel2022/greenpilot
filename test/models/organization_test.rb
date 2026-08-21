require "test_helper"

class OrganizationTest < ActiveSupport::TestCase
  test "fixtures are loaded" do
    assert_equal 2, Organization.count
    assert_equal 7, User.count
  end
end