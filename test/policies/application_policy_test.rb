
require "test_helper"

class ApplicationPolicyTest < ActiveSupport::TestCase
  def setup
  @organization = organizations(:organization_a)
  @other_organization = organizations(:organization_b)
  @user = users(:owner_a)
  @other_user = users(:member_b)
  @record = customers(:customer_a)
  @other_record = customers(:customer_b)

  @user.update!(organization: @organization)
  @other_user.update!(organization: @other_organization)

  @record.update!(organization: @organization)
  @other_record.update!(organization: @other_organization)
end

  # ---------------------------------------------------------------------------
  # Default permissions
  # ---------------------------------------------------------------------------

  test "denies index by default" do
    policy = ApplicationPolicy.new(@user, @record)

    assert_not policy.index?
  end

  test "denies show by default" do
    policy = ApplicationPolicy.new(@user, @record)

    assert_not policy.show?
  end

  test "denies create by default" do
    policy = ApplicationPolicy.new(@user, @record)

    assert_not policy.create?
  end

  test "denies update by default" do
    policy = ApplicationPolicy.new(@user, @record)

    assert_not policy.update?
  end

  test "denies destroy by default" do
    policy = ApplicationPolicy.new(@user, @record)

    assert_not policy.destroy?
  end

  # ---------------------------------------------------------------------------
  # Delegated permissions
  # ---------------------------------------------------------------------------

  test "new delegates to create" do
    policy = ApplicationPolicy.new(@user, @record)

    assert_equal policy.create?, policy.new?
  end

  test "edit delegates to update" do
    policy = ApplicationPolicy.new(@user, @record)

    assert_equal policy.update?, policy.edit?
  end

  # ---------------------------------------------------------------------------
  # Authentication
  # ---------------------------------------------------------------------------

  test "same_organization? is false for nil user" do
    policy = ApplicationPolicy.new(nil, @record)

    assert_not policy.send(:same_organization?)
  end

  test "same_organization? is true for authenticated user in same organization" do
    policy = ApplicationPolicy.new(@user, @record)

    assert policy.send(:same_organization?)
  end

  test "same_organization? is false for user in another organization" do
    policy = ApplicationPolicy.new(@other_user, @record)

    assert_not policy.send(:same_organization?)
  end

  # ---------------------------------------------------------------------------
  # Role helpers
  # ---------------------------------------------------------------------------

  test "owner_or_admin? is true for owner" do
    @user.update!(role: :owner)

    policy = ApplicationPolicy.new(@user, @record)

    assert policy.send(:owner_or_admin?)
  end

  test "owner_or_admin? is true for admin" do
    @user.update!(role: :admin)

    policy = ApplicationPolicy.new(@user, @record)

    assert policy.send(:owner_or_admin?)
  end

  test "owner_or_admin? is false for manager" do
    @user.update!(role: :manager)

    policy = ApplicationPolicy.new(@user, @record)

    assert_not policy.send(:owner_or_admin?)
  end

  test "management? is true for owner admin and manager" do
    %i[owner admin manager].each do |role|
      @user.update!(role: role)

      policy = ApplicationPolicy.new(@user, @record)

      assert policy.send(:management?), "#{role} should be management"
    end
  end

  test "management? is false for non management roles" do
    %i[accountant field_worker member].each do |role|
      @user.update!(role: role)

      policy = ApplicationPolicy.new(@user, @record)

      assert_not policy.send(:management?), "#{role} should not be management"
    end
  end

  # ---------------------------------------------------------------------------
  # Scope
  # ---------------------------------------------------------------------------

  test "base scope raises NotImplementedError" do
    scope = ApplicationPolicy::Scope.new(@user, Customer.all)

    assert_raises(NotImplementedError) do
      scope.resolve
    end
  end
end