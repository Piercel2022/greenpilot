require "test_helper"

class TeamTest < ActiveSupport::TestCase
  setup do
    @organization = Organization.create!(name: "GreenPilot Team Test", slug: "greenpilot-team-test")
  end

  test "belongs to organization" do
    assert_equal :belongs_to, Team.reflect_on_association(:organization).macro
  end

  test "has memberships users and jobs" do
    assert_equal :has_many, Team.reflect_on_association(:team_memberships).macro
    assert_equal :has_many, Team.reflect_on_association(:users).macro
    assert_equal :has_many, Team.reflect_on_association(:jobs).macro
  end

  test "requires code and name" do
    team = Team.new(organization: @organization)

    refute team.valid?
    assert team.errors[:code].any?
    assert team.errors[:name].any?
  end

  test "code is unique within organization" do
    Team.create!(
      organization: @organization,
      code: "TEAM-01",
      name: "Team One"
    )

    duplicate = Team.new(
      organization: @organization,
      code: "TEAM-01",
      name: "Another Team"
    )

    refute duplicate.valid?
    assert duplicate.errors[:code].any?
  end
end
