require "test_helper"

class TeamMembershipTest < ActiveSupport::TestCase
  setup do
    @organization = Organization.create!(name: "GreenPilot Membership Test", slug: "greenpilot-membership-test")

    @team = Team.create!(
      organization: @organization,
      code: "TEAM-01",
      name: "Team One"
    )

    @user = User.create!(
  organization: @organization,
  email: "worker@example.com",
  first_name: "Field",
  last_name: "Worker",
  password: "password123",
  password_confirmation: "password123"
  )
  end

  test "belongs to organization team and user" do
    assert_equal :belongs_to, TeamMembership.reflect_on_association(:organization).macro
    assert_equal :belongs_to, TeamMembership.reflect_on_association(:team).macro
    assert_equal :belongs_to, TeamMembership.reflect_on_association(:user).macro
  end

  test "requires role" do
    membership = TeamMembership.new(
      organization: @organization,
      team: @team,
      user: @user,
      role: nil
    )

    refute membership.valid?
    assert membership.errors[:role].any?
  end

  test "user can only belong once to a team" do
    TeamMembership.create!(
      organization: @organization,
      team: @team,
      user: @user,
      role: "member"
    )

    duplicate = TeamMembership.new(
      organization: @organization,
      team: @team,
      user: @user,
      role: "member"
    )

    refute duplicate.valid?
    assert duplicate.errors[:user_id].any?
  end

  test "rejects team from another organization" do
    membership = TeamMembership.new(
      organization: organizations(:organization_a),
      team: teams(:team_b),
      user: users(:member_a),
      role: "member"
    )

    assert_not membership.valid?

    assert_includes membership.errors.full_messages,
                  "Team must belong to the same organization"
  end

  test "rejects user from another organization" do
    membership = TeamMembership.new(
      organization: organizations(:organization_a),
      team: teams(:team_a),
      user: users(:member_b),
      role: "member"
    )

    assert_not membership.valid?

    assert_includes membership.errors.full_messages,
                  "User must belong to the same organization"
  end

  test "active and inactive scopes work" do
    active = TeamMembership.create!(
      organization: @organization,
      team: @team,
      user: @user,
      role: "member",
      active: true
    )

    assert_includes TeamMembership.active, active
    assert_not_includes TeamMembership.inactive, active
  end
end
