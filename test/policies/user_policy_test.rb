require "test_helper"

class UserPolicyTest < ActiveSupport::TestCase
  test "manager can list users" do
    user = users(:manager_a)

    assert UserPolicy.new(user, User).index?
  end

  test "member cannot list users" do
    user = users(:member_a)

    assert_not UserPolicy.new(user, User).index?
  end

  test "manager can view another user from same organization" do
    user = users(:manager_a)
    target = users(:member_a)

    assert UserPolicy.new(user, target).show?
  end

  test "member cannot view another user" do
    user = users(:member_a)
    target = users(:manager_a)

    assert_not UserPolicy.new(user, target).show?
  end

  test "manager cannot view user from another organization" do
    user = users(:manager_a)
    target = users(:member_b)

    assert_not UserPolicy.new(user, target).show?
  end

  test "owner can create user" do
    user = users(:owner_a)

    target = User.new(
      organization: user.organization,
      first_name: "New",
      last_name: "User",
      email: "new.owner.user@example.test",
      role: :member
    )

    assert UserPolicy.new(user, target).create?
  end

  test "admin can create user" do
    user = users(:admin_a)

    target = User.new(
      organization: user.organization,
      first_name: "New",
      last_name: "User",
      email: "new.admin.user@example.test",
      role: :member
    )

    assert UserPolicy.new(user, target).create?
  end

  test "manager can create user" do
    user = users(:manager_a)

    target = User.new(
      organization: user.organization,
      first_name: "New",
      last_name: "User",
      email: "new.manager.user@example.test",
      role: :member
    )

    assert UserPolicy.new(user, target).create?
  end

  test "member cannot create user" do
    user = users(:member_a)

    target = User.new(
      organization: user.organization,
      first_name: "New",
      last_name: "User",
      email: "new.member.user@example.test",
      role: :member
    )

    assert_not UserPolicy.new(user, target).create?
  end

  test "owner can update user from same organization" do
    user = users(:owner_a)
    target = users(:member_a)

    assert UserPolicy.new(user, target).update?
  end

  test "admin can update user from same organization" do
    user = users(:admin_a)
    target = users(:member_a)

    assert UserPolicy.new(user, target).update?
  end

  test "manager cannot update user" do
    user = users(:manager_a)
    target = users(:member_a)

    assert_not UserPolicy.new(user, target).update?
  end

  test "admin cannot update user from another organization" do
    user = users(:admin_a)
    target = users(:member_b)

    assert_not UserPolicy.new(user, target).update?
  end

  test "owner can destroy user from same organization" do
    user = users(:owner_a)
    target = users(:member_a)

    assert UserPolicy.new(user, target).destroy?
  end

  test "admin cannot destroy user" do
    user = users(:admin_a)
    target = users(:member_a)

    assert_not UserPolicy.new(user, target).destroy?
  end

  test "manager cannot destroy user" do
    user = users(:manager_a)
    target = users(:member_a)

    assert_not UserPolicy.new(user, target).destroy?
  end

  test "owner cannot destroy user from another organization" do
    user = users(:owner_a)
    target = users(:member_b)

    assert_not UserPolicy.new(user, target).destroy?
  end

  test "scope returns only users from user's organization" do
    user = users(:member_a)

    result = UserPolicy::Scope
      .new(user, User.all)
      .resolve

    assert result.all? do |target|
      target.organization_id == user.organization_id
    end
  end
end