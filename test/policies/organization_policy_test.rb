require "test_helper"

class OrganizationPolicyTest < ActiveSupport::TestCase
  test "authenticated user can view their organization" do
    user = users(:member_a)
    organization = organizations(:organization_a)

    assert OrganizationPolicy.new(user, organization).show?
  end

  test "user cannot view another organization" do
    user = users(:member_a)
    organization = organizations(:organization_b)

    assert_not OrganizationPolicy.new(user, organization).show?
  end

  test "owner can update their organization" do
    user = users(:owner_a)
    organization = organizations(:organization_a)

    assert OrganizationPolicy.new(user, organization).update?
  end

  test "admin can update their organization" do
    user = users(:admin_a)
    organization = organizations(:organization_a)

    assert OrganizationPolicy.new(user, organization).update?
  end

  test "manager cannot update organization" do
    user = users(:manager_a)
    organization = organizations(:organization_a)

    assert_not OrganizationPolicy.new(user, organization).update?
  end

  test "member cannot update organization" do
    user = users(:member_a)
    organization = organizations(:organization_a)

    assert_not OrganizationPolicy.new(user, organization).update?
  end

  test "only owner can destroy organization" do
    user = users(:owner_a)
    organization = organizations(:organization_a)

    assert OrganizationPolicy.new(user, organization).destroy?
  end

  test "admin cannot destroy organization" do
    user = users(:admin_a)
    organization = organizations(:organization_a)

    assert_not OrganizationPolicy.new(user, organization).destroy?
  end

  test "scope returns only user's organization" do
    user = users(:member_a)

    result = OrganizationPolicy::Scope
      .new(user, Organization.all)
      .resolve

    assert_equal [user.organization], result.to_a
  end
end