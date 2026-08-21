require "test_helper"

class CustomerPolicyTest < ActiveSupport::TestCase
  test "authenticated user can list customers" do
    user = users(:member_a)

    assert CustomerPolicy.new(user, Customer).index?
  end

  test "user can view customer from same organization" do
    user = users(:member_a)
    customer = customers(:customer_a)

    assert CustomerPolicy.new(user, customer).show?
  end

  test "user cannot view customer from another organization" do
    user = users(:member_a)
    customer = customers(:customer_b)

    assert_not CustomerPolicy.new(user, customer).show?
  end

  test "owner can create customer" do
    user = users(:owner_a)

    customer = Customer.new(
      organization: user.organization,
      customer_type: :individual
    )

    assert CustomerPolicy.new(user, customer).create?
  end

  test "admin can create customer" do
    user = users(:admin_a)

    customer = Customer.new(
      organization: user.organization,
      customer_type: :individual
    )

    assert CustomerPolicy.new(user, customer).create?
  end

  test "manager can create customer" do
    user = users(:manager_a)

    customer = Customer.new(
      organization: user.organization,
      customer_type: :individual
    )

    assert CustomerPolicy.new(user, customer).create?
  end

  test "member cannot create customer" do
    user = users(:member_a)

    customer = Customer.new(
      organization: user.organization,
      customer_type: :individual
    )

    assert_not CustomerPolicy.new(user, customer).create?
  end

  test "accountant cannot create customer" do
    user = users(:accountant_a)

    customer = Customer.new(
      organization: user.organization,
      customer_type: :individual
    )

    assert_not CustomerPolicy.new(user, customer).create?
  end

  test "manager can update customer from same organization" do
    user = users(:manager_a)
    customer = customers(:customer_a)

    assert CustomerPolicy.new(user, customer).update?
  end

  test "member cannot update customer" do
    user = users(:member_a)
    customer = customers(:customer_a)

    assert_not CustomerPolicy.new(user, customer).update?
  end

  test "manager cannot update customer from another organization" do
    user = users(:manager_a)
    customer = customers(:customer_b)

    assert_not CustomerPolicy.new(user, customer).update?
  end

  test "owner can destroy customer" do
    user = users(:owner_a)
    customer = customers(:customer_a)

    assert CustomerPolicy.new(user, customer).destroy?
  end

  test "admin can destroy customer" do
    user = users(:admin_a)
    customer = customers(:customer_a)

    assert CustomerPolicy.new(user, customer).destroy?
  end

  test "manager cannot destroy customer" do
    user = users(:manager_a)
    customer = customers(:customer_a)

    assert_not CustomerPolicy.new(user, customer).destroy?
  end

  test "owner cannot destroy customer from another organization" do
    user = users(:owner_a)
    customer = customers(:customer_b)

    assert_not CustomerPolicy.new(user, customer).destroy?
  end

  test "scope returns only customers from user's organization" do
    user = users(:member_a)

    result = CustomerPolicy::Scope
      .new(user, Customer.all)
      .resolve

    assert result.all? do |customer|
      customer.organization_id == user.organization_id
    end
  end
end