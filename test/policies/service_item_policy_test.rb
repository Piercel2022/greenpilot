require "test_helper"

class ServiceItemPolicyTest < ActiveSupport::TestCase
  test "authenticated user can list service items" do
    user = users(:member_a)

    assert ServiceItemPolicy.new(user, ServiceItem).index?
  end

  test "user can view service item from same organization" do
    user = users(:member_a)
    item = service_items(:item_a)

    assert ServiceItemPolicy.new(user, item).show?
  end

  test "user cannot view service item from another organization" do
    user = users(:member_a)
    item = service_items(:item_b)

    assert_not ServiceItemPolicy.new(user, item).show?
  end

  test "owner can create service item" do
    user = users(:owner_a)

    item = ServiceItem.new(
      organization: user.organization,
      service_category: service_categories(:category_a),
      code: "NEW-OWNER",
      name: "Nouvelle prestation Owner"
    )

    assert ServiceItemPolicy.new(user, item).create?
  end

  test "admin can create service item" do
    user = users(:admin_a)

    item = ServiceItem.new(
      organization: user.organization,
      service_category: service_categories(:category_a),
      code: "NEW-ADMIN",
      name: "Nouvelle prestation Admin"
    )

    assert ServiceItemPolicy.new(user, item).create?
  end

  test "manager can create service item" do
    user = users(:manager_a)

    item = ServiceItem.new(
      organization: user.organization,
      service_category: service_categories(:category_a),
      code: "NEW-MANAGER",
      name: "Nouvelle prestation Manager"
    )

    assert ServiceItemPolicy.new(user, item).create?
  end

  test "member cannot create service item" do
    user = users(:member_a)

    item = ServiceItem.new(
      organization: user.organization,
      service_category: service_categories(:category_a),
      code: "NEW-MEMBER",
      name: "Nouvelle prestation Member"
    )

    assert_not ServiceItemPolicy.new(user, item).create?
  end

  test "accountant cannot create service item" do
    user = users(:accountant_a)

    item = ServiceItem.new(
      organization: user.organization,
      service_category: service_categories(:category_a),
      code: "NEW-ACCOUNTANT",
      name: "Nouvelle prestation Accountant"
    )

    assert_not ServiceItemPolicy.new(user, item).create?
  end

  test "field worker cannot create service item" do
    user = users(:field_worker_a)

    item = ServiceItem.new(
      organization: user.organization,
      service_category: service_categories(:category_a),
      code: "NEW-FIELD",
      name: "Nouvelle prestation Field"
    )

    assert_not ServiceItemPolicy.new(user, item).create?
  end

  test "manager can update service item from same organization" do
    user = users(:manager_a)
    item = service_items(:item_a)

    assert ServiceItemPolicy.new(user, item).update?
  end

  test "member cannot update service item" do
    user = users(:member_a)
    item = service_items(:item_a)

    assert_not ServiceItemPolicy.new(user, item).update?
  end

  test "manager cannot update service item from another organization" do
    user = users(:manager_a)
    item = service_items(:item_b)

    assert_not ServiceItemPolicy.new(user, item).update?
  end

  test "owner can destroy service item" do
    user = users(:owner_a)
    item = service_items(:item_a)

    assert ServiceItemPolicy.new(user, item).destroy?
  end

  test "admin can destroy service item" do
    user = users(:admin_a)
    item = service_items(:item_a)

    assert ServiceItemPolicy.new(user, item).destroy?
  end

  test "manager cannot destroy service item" do
    user = users(:manager_a)
    item = service_items(:item_a)

    assert_not ServiceItemPolicy.new(user, item).destroy?
  end

  test "owner cannot destroy service item from another organization" do
    user = users(:owner_a)
    item = service_items(:item_b)

    assert_not ServiceItemPolicy.new(user, item).destroy?
  end

  test "cannot create service item with foreign service category" do
    user = users(:manager_a)

    item = ServiceItem.new(
      organization: organizations(:organization_a),
      service_category: service_categories(:category_b),
      code: "CROSS-CATEGORY",
      name: "Prestation cross organization"
    )

    assert_not ServiceItemPolicy.new(user, item).create?
  end

  test "cannot create service item with foreign organization" do
    user = users(:manager_a)

    item = ServiceItem.new(
      organization: organizations(:organization_b),
      service_category: service_categories(:category_a),
      code: "CROSS-ORGANIZATION",
      name: "Prestation cross organization"
    )

    assert_not ServiceItemPolicy.new(user, item).create?
  end

  test "scope returns only service items from user's organization" do
    user = users(:member_a)

    result = ServiceItemPolicy::Scope
      .new(user, ServiceItem.all)
      .resolve

    assert result.all? do |item|
      item.organization_id == user.organization_id &&
        item.service_category.organization_id == user.organization_id
    end
  end
end