require "test_helper"

class TeamMembershipPolicyTest < ActiveSupport::TestCase
  test "authenticated user can list team memberships" do
    user = users(:member_a)

    assert TeamMembershipPolicy.new(user, TeamMembership).index?
  end

  test "user can view membership from same organization" do
    user = users(:member_a)
    membership = team_memberships(:membership_a)

    assert TeamMembershipPolicy.new(user, membership).show?
  end

  test "user cannot view membership from another organization" do
    user = users(:member_a)
    membership = team_memberships(:membership_b)

    assert_not TeamMembershipPolicy.new(user, membership).show?
  end

  test "owner can create team membership" do
    user = users(:owner_a)

    membership = TeamMembership.new(
      organization: user.organization,
      team: teams(:team_a),
      user: users(:member_a),
      role: "member"
    )

    assert TeamMembershipPolicy.new(user, membership).create?
  end

  test "admin can create team membership" do
    user = users(:admin_a)

    membership = TeamMembership.new(
      organization: user.organization,
      team: teams(:team_a),
      user: users(:member_a),
      role: "member"
    )

    assert TeamMembershipPolicy.new(user, membership).create?
  end

  test "manager can create team membership" do
    user = users(:manager_a)

    membership = TeamMembership.new(
      organization: user.organization,
      team: teams(:team_a),
      user: users(:member_a),
      role: "member"
    )

    assert TeamMembershipPolicy.new(user, membership).create?
  end

  test "member cannot create team membership" do
    user = users(:member_a)

    membership = TeamMembership.new(
      organization: user.organization,
      team: teams(:team_a),
      user: users(:member_a),
      role: "member"
    )

    assert_not TeamMembershipPolicy.new(user, membership).create?
  end

  test "accountant cannot create team membership" do
    user = users(:accountant_a)

    membership = TeamMembership.new(
      organization: user.organization,
      team: teams(:team_a),
      user: users(:member_a),
      role: "member"
    )

    assert_not TeamMembershipPolicy.new(user, membership).create?
  end

  test "manager can update membership from same organization" do
    user = users(:manager_a)
    membership = team_memberships(:membership_a)

    assert TeamMembershipPolicy.new(user, membership).update?
  end

  test "member cannot update membership" do
    user = users(:member_a)
    membership = team_memberships(:membership_a)

    assert_not TeamMembershipPolicy.new(user, membership).update?
  end

  test "manager cannot update membership from another organization" do
    user = users(:manager_a)
    membership = team_memberships(:membership_b)

    assert_not TeamMembershipPolicy.new(user, membership).update?
  end

  test "manager can destroy membership from same organization" do
    user = users(:manager_a)
    membership = team_memberships(:membership_a)

    assert TeamMembershipPolicy.new(user, membership).destroy?
  end

  test "accountant cannot destroy membership" do
    user = users(:accountant_a)
    membership = team_memberships(:membership_a)

    assert_not TeamMembershipPolicy.new(user, membership).destroy?
  end

  test "manager cannot destroy membership from another organization" do
    user = users(:manager_a)
    membership = team_memberships(:membership_b)

    assert_not TeamMembershipPolicy.new(user, membership).destroy?
  end

  test "membership with foreign team is rejected" do
    user = users(:manager_a)

    membership = TeamMembership.new(
      organization: organizations(:organization_a),
      team: teams(:team_b),
      user: users(:member_a),
      role: "member"
    )

    assert_not TeamMembershipPolicy.new(user, membership).create?
  end

  test "membership with foreign user is rejected" do
    user = users(:manager_a)

    membership = TeamMembership.new(
      organization: organizations(:organization_a),
      team: teams(:team_a),
      user: users(:member_b),
      role: "member"
    )

    assert_not TeamMembershipPolicy.new(user, membership).create?
  end

  test "membership with foreign organization is rejected" do
    user = users(:manager_a)

    membership = TeamMembership.new(
      organization: organizations(:organization_b),
      team: teams(:team_a),
      user: users(:member_a),
      role: "member"
    )

    assert_not TeamMembershipPolicy.new(user, membership).create?
  end

  test "scope returns only memberships from user's organization" do
    user = users(:member_a)

    result = TeamMembershipPolicy::Scope
      .new(user, TeamMembership.all)
      .resolve

    assert result.all? do |membership|
      membership.organization_id == user.organization_id
    end
  end
end