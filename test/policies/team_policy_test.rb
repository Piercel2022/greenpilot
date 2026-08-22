require "test_helper"

class TeamPolicyTest < ActiveSupport::TestCase
  test "authenticated user can list teams" do
    user = users(:member_a)

    assert TeamPolicy.new(user, Team).index?
  end

  test "user can view team from same organization" do
    user = users(:member_a)
    team = teams(:team_a)

    assert TeamPolicy.new(user, team).show?
  end

  test "user cannot view team from another organization" do
    user = users(:member_a)
    team = teams(:team_b)

    assert_not TeamPolicy.new(user, team).show?
  end

  test "owner can create team" do
    user = users(:owner_a)

    team = Team.new(
      organization: user.organization,
      code: "TEAM-NEW-OWNER",
      name: "Nouvelle équipe Owner"
    )

    assert TeamPolicy.new(user, team).create?
  end

  test "admin can create team" do
    user = users(:admin_a)

    team = Team.new(
      organization: user.organization,
      code: "TEAM-NEW-ADMIN",
      name: "Nouvelle équipe Admin"
    )

    assert TeamPolicy.new(user, team).create?
  end

  test "manager can create team" do
    user = users(:manager_a)

    team = Team.new(
      organization: user.organization,
      code: "TEAM-NEW-MANAGER",
      name: "Nouvelle équipe Manager"
    )

    assert TeamPolicy.new(user, team).create?
  end

  test "accountant cannot create team" do
    user = users(:accountant_a)

    team = Team.new(
      organization: user.organization,
      code: "TEAM-NEW-ACCOUNTANT",
      name: "Nouvelle équipe Accountant"
    )

    assert_not TeamPolicy.new(user, team).create?
  end

  test "field worker cannot create team" do
    user = users(:field_worker_a)

    team = Team.new(
      organization: user.organization,
      code: "TEAM-NEW-FIELD",
      name: "Nouvelle équipe Field"
    )

    assert_not TeamPolicy.new(user, team).create?
  end

  test "member cannot create team" do
    user = users(:member_a)

    team = Team.new(
      organization: user.organization,
      code: "TEAM-NEW-MEMBER",
      name: "Nouvelle équipe Member"
    )

    assert_not TeamPolicy.new(user, team).create?
  end

  test "manager can update team from same organization" do
    user = users(:manager_a)
    team = teams(:team_a)

    assert TeamPolicy.new(user, team).update?
  end

  test "member cannot update team" do
    user = users(:member_a)
    team = teams(:team_a)

    assert_not TeamPolicy.new(user, team).update?
  end

  test "manager cannot update team from another organization" do
    user = users(:manager_a)
    team = teams(:team_b)

    assert_not TeamPolicy.new(user, team).update?
  end

  test "owner can destroy team" do
    user = users(:owner_a)
    team = teams(:team_a)

    assert TeamPolicy.new(user, team).destroy?
  end

  test "admin can destroy team" do
    user = users(:admin_a)
    team = teams(:team_a)

    assert TeamPolicy.new(user, team).destroy?
  end

  test "manager cannot destroy team" do
    user = users(:manager_a)
    team = teams(:team_a)

    assert_not TeamPolicy.new(user, team).destroy?
  end

  test "owner cannot destroy team from another organization" do
    user = users(:owner_a)
    team = teams(:team_b)

    assert_not TeamPolicy.new(user, team).destroy?
  end

  test "scope returns only teams from user's organization" do
    user = users(:member_a)

    result = TeamPolicy::Scope
      .new(user, Team.all)
      .resolve

    assert result.all? do |team|
      team.organization_id == user.organization_id
    end
  end
end