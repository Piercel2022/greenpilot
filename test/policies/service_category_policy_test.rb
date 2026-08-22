require "test_helper"

class ServiceCategoryPolicyTest < ActiveSupport::TestCase
  test "authenticated user can list service categories" do
    user = users(:member_a)

    assert ServiceCategoryPolicy.new(user, ServiceCategory).index?
  end

  test "user can view service category from same organization" do
    user = users(:member_a)
    category = service_categories(:category_a)

    assert ServiceCategoryPolicy.new(user, category).show?
  end

  test "user cannot view service category from another organization" do
    user = users(:member_a)
    category = service_categories(:category_b)

    assert_not ServiceCategoryPolicy.new(user, category).show?
  end

  test "owner can create service category" do
    user = users(:owner_a)

    category = ServiceCategory.new(
      organization: user.organization,
      code: "NEW-OWNER",
      name: "Nouvelle catégorie Owner"
    )

    assert ServiceCategoryPolicy.new(user, category).create?
  end

  test "admin can create service category" do
    user = users(:admin_a)

    category = ServiceCategory.new(
      organization: user.organization,
      code: "NEW-ADMIN",
      name: "Nouvelle catégorie Admin"
    )

    assert ServiceCategoryPolicy.new(user, category).create?
  end

  test "manager can create service category" do
    user = users(:manager_a)

    category = ServiceCategory.new(
      organization: user.organization,
      code: "NEW-MANAGER",
      name: "Nouvelle catégorie Manager"
    )

    assert ServiceCategoryPolicy.new(user, category).create?
  end

  test "member cannot create service category" do
    user = users(:member_a)

    category = ServiceCategory.new(
      organization: user.organization,
      code: "NEW-MEMBER",
      name: "Nouvelle catégorie Member"
    )

    assert_not ServiceCategoryPolicy.new(user, category).create?
  end

  test "accountant cannot create service category" do
    user = users(:accountant_a)

    category = ServiceCategory.new(
      organization: user.organization,
      code: "NEW-ACCOUNTANT",
      name: "Nouvelle catégorie Accountant"
    )

    assert_not ServiceCategoryPolicy.new(user, category).create?
  end

  test "field worker cannot create service category" do
    user = users(:field_worker_a)

    category = ServiceCategory.new(
      organization: user.organization,
      code: "NEW-FIELD",
      name: "Nouvelle catégorie Field"
    )

    assert_not ServiceCategoryPolicy.new(user, category).create?
  end

  test "manager can update service category from same organization" do
    user = users(:manager_a)
    category = service_categories(:category_a)

    assert ServiceCategoryPolicy.new(user, category).update?
  end

  test "member cannot update service category" do
    user = users(:member_a)
    category = service_categories(:category_a)

    assert_not ServiceCategoryPolicy.new(user, category).update?
  end

  test "manager cannot update service category from another organization" do
    user = users(:manager_a)
    category = service_categories(:category_b)

    assert_not ServiceCategoryPolicy.new(user, category).update?
  end

  test "owner can destroy service category" do
    user = users(:owner_a)
    category = service_categories(:category_a)

    assert ServiceCategoryPolicy.new(user, category).destroy?
  end

  test "admin can destroy service category" do
    user = users(:admin_a)
    category = service_categories(:category_a)

    assert ServiceCategoryPolicy.new(user, category).destroy?
  end

  test "manager cannot destroy service category" do
    user = users(:manager_a)
    category = service_categories(:category_a)

    assert_not ServiceCategoryPolicy.new(user, category).destroy?
  end

  test "owner cannot destroy service category from another organization" do
    user = users(:owner_a)
    category = service_categories(:category_b)

    assert_not ServiceCategoryPolicy.new(user, category).destroy?
  end

  test "scope returns only service categories from user's organization" do
    user = users(:member_a)

    result = ServiceCategoryPolicy::Scope
      .new(user, ServiceCategory.all)
      .resolve

    assert result.all? do |category|
      category.organization_id == user.organization_id
    end
  end
end