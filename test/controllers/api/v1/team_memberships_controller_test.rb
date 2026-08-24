require "test_helper"

class Api::V1::TeamMembershipsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organization = Organization.create!(
      name: "GreenPilot Memberships Test",
      slug: "greenpilot-memberships-test"
    )

    @other_organization = Organization.create!(
      name: "Other Membership Organization",
      slug: "other-membership-org"
    )

    @manager = User.create!(
      organization: @organization,
      email: "manager-memberships@example.com",
      first_name: "Membership",
      last_name: "Manager",
      role: "manager",
      password: "password123",
      password_confirmation: "password123"
    )

    @member = User.create!(
      organization: @organization,
      email: "member-memberships@example.com",
      first_name: "Team",
      last_name: "Member",
      role: "member",
      password: "password123",
      password_confirmation: "password123"
    )

    @other_user = User.create!(
      organization: @other_organization,
      email: "other-memberships@example.com",
      first_name: "Other",
      last_name: "User",
      role: "member",
      password: "password123",
      password_confirmation: "password123"
    )

    @team = Team.create!(
      organization: @organization,
      code: "TEAM-MEM-01",
      name: "Équipe Membership",
      active: true
    )

    @other_team = Team.create!(
      organization: @other_organization,
      code: "TEAM-OTHER-01",
      name: "Other Team",
      active: true
    )

    @team_membership = TeamMembership.create!(
      organization: @organization,
      team: @team,
      user: @member,
      role: "member",
      active: true,
      start_date: Date.current
    )

    @other_membership = TeamMembership.create!(
      organization: @other_organization,
      team: @other_team,
      user: @other_user,
      role: "member",
      active: true,
      start_date: Date.current
    )

    @token = JwtService.encode(@manager)
  end

  test "index requires authentication" do
    get "/api/v1/team_memberships"

    assert_response :unauthorized
  end

  test "index returns memberships from authenticated user's organization" do
    get "/api/v1/team_memberships",
        headers: {
          "Authorization" => "Bearer #{@token}"
        }

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal 1, body.length
    assert_equal @team_membership.id, body.first["id"]
  end

  test "show returns membership from same organization" do
    get "/api/v1/team_memberships/#{@team_membership.id}",
        headers: {
          "Authorization" => "Bearer #{@token}"
        }

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal @team_membership.id, body["id"]
    assert_equal @team.id, body["team_id"]
    assert_equal @member.id, body["user_id"]
  end

  test "show does not expose membership from another organization" do
    get "/api/v1/team_memberships/#{@other_membership.id}",
        headers: {
          "Authorization" => "Bearer #{@token}"
        }

    assert_response :not_found
  end

  test "manager can create membership" do
    new_user = User.create!(
      organization: @organization,
      email: "new-membership-user@example.com",
      first_name: "New",
      last_name: "Member",
      role: "member",
      password: "password123",
      password_confirmation: "password123"
    )

    assert_difference("TeamMembership.count", 1) do
      post "/api/v1/team_memberships",
           params: {
             team_membership: {
               team_id: @team.id,
               user_id: new_user.id,
               role: "member",
               active: true,
               start_date: Date.current
             }
           },
           headers: {
             "Authorization" => "Bearer #{@token}"
           }
    end

    assert_response :created

    body = JSON.parse(response.body)

    assert_equal @organization.id, body["organization_id"]
    assert_equal @team.id, body["team_id"]
    assert_equal new_user.id, body["user_id"]
    assert_equal "member", body["role"]
  end

  test "manager cannot create membership with team from another organization" do
    assert_no_difference("TeamMembership.count") do
      post "/api/v1/team_memberships",
           params: {
             team_membership: {
               team_id: @other_team.id,
               user_id: @member.id,
               role: "member"
             }
           },
           headers: {
             "Authorization" => "Bearer #{@token}"
           }
    end

    assert_response :forbidden
  end

  test "manager cannot create membership with user from another organization" do
    assert_no_difference("TeamMembership.count") do
      post "/api/v1/team_memberships",
           params: {
             team_membership: {
               team_id: @team.id,
               user_id: @other_user.id,
               role: "member"
             }
           },
           headers: {
             "Authorization" => "Bearer #{@token}"
           }
    end

    assert_response :forbidden
  end

  test "manager can update membership" do
    patch "/api/v1/team_memberships/#{@team_membership.id}",
          params: {
            team_membership: {
              role: "leader",
              active: false,
              end_date: Date.current
            }
          },
          headers: {
            "Authorization" => "Bearer #{@token}"
          }

    assert_response :success

    @team_membership.reload

    assert_equal "leader", @team_membership.role
    assert_equal false, @team_membership.active
    assert_equal Date.current, @team_membership.end_date
  end

  test "manager cannot update membership from another organization" do
    patch "/api/v1/team_memberships/#{@other_membership.id}",
          params: {
            team_membership: {
              role: "leader"
            }
          },
          headers: {
            "Authorization" => "Bearer #{@token}"
          }

    assert_response :not_found

    assert_equal "member", @other_membership.reload.role
  end

  test "duplicate team membership is rejected" do
    assert_no_difference("TeamMembership.count") do
      post "/api/v1/team_memberships",
           params: {
             team_membership: {
               team_id: @team.id,
               user_id: @member.id,
               role: "member"
             }
           },
           headers: {
             "Authorization" => "Bearer #{@token}"
           }
    end

    assert_response :unprocessable_entity
  end

  test "role is required" do
    new_user = User.create!(
      organization: @organization,
      email: "role-test@example.com",
      first_name: "Role",
      last_name: "Test",
      role: "member",
      password: "password123",
      password_confirmation: "password123"
    )

    assert_no_difference("TeamMembership.count") do
      post "/api/v1/team_memberships",
           params: {
             team_membership: {
               team_id: @team.id,
               user_id: new_user.id,
               role: ""
             }
           },
           headers: {
             "Authorization" => "Bearer #{@token}"
           }
    end

    assert_response :unprocessable_entity
  end
end