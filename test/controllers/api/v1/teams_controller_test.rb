require "test_helper"

class Api::V1::TeamsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organization = Organization.create!(
      name: "GreenPilot Teams Test",
      slug: "greenpilot-teams-test"
    )

    @other_organization = Organization.create!(
      name: "Other Teams Organization",
      slug: "other-teams-org"
    )

    @manager = User.create!(
      organization: @organization,
      email: "manager-teams@example.com",
      first_name: "Team",
      last_name: "Manager",
      role: "manager",
      password: "password123",
      password_confirmation: "password123"
    )

    @team = Team.create!(
      organization: @organization,
      code: "TEAM-01",
      name: "Équipe Paysage",
      description: "Équipe principale",
      color: "#22C55E",
      active: true
    )

    @other_team = Team.create!(
      organization: @other_organization,
      code: "TEAM-OTHER",
      name: "Other Team",
      active: true
    )

    @token = JwtService.encode(@manager)
  end

  test "index requires authentication" do
    get "/api/v1/teams"

    assert_response :unauthorized
  end

  test "index returns teams from authenticated user's organization" do
    get "/api/v1/teams",
        headers: {
          "Authorization" => "Bearer #{@token}"
        }

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal 1, body.length
    assert_equal @team.id, body.first["id"]
  end

  test "show returns team from same organization" do
    get "/api/v1/teams/#{@team.id}",
        headers: {
          "Authorization" => "Bearer #{@token}"
        }

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal @team.id, body["id"]
    assert_equal "TEAM-01", body["code"]
    assert_equal "Équipe Paysage", body["name"]
  end

  test "show does not expose team from another organization" do
    get "/api/v1/teams/#{@other_team.id}",
        headers: {
          "Authorization" => "Bearer #{@token}"
        }

    assert_response :not_found
  end

  test "manager can create team" do
    assert_difference("Team.count", 1) do
      post "/api/v1/teams",
           params: {
             team: {
               code: "TEAM-02",
               name: "Équipe Entretien",
               description: "Équipe entretien jardins",
               color: "#3B82F6",
               active: true
             }
           },
           headers: {
             "Authorization" => "Bearer #{@token}"
           }
    end

    assert_response :created

    body = JSON.parse(response.body)

    assert_equal "TEAM-02", body["code"]
    assert_equal "Équipe Entretien", body["name"]
    assert_equal @organization.id, body["organization_id"]
  end

  test "manager can update team" do
    patch "/api/v1/teams/#{@team.id}",
          params: {
            team: {
              name: "Équipe Paysage Premium",
              description: "Équipe principale mise à jour"
            }
          },
          headers: {
            "Authorization" => "Bearer #{@token}"
          }

    assert_response :success

    @team.reload

    assert_equal "Équipe Paysage Premium", @team.name
    assert_equal "Équipe principale mise à jour", @team.description
  end

  test "manager cannot update team from another organization" do
    patch "/api/v1/teams/#{@other_team.id}",
          params: {
            team: {
              name: "Unauthorized Update"
            }
          },
          headers: {
            "Authorization" => "Bearer #{@token}"
          }

    assert_response :not_found

    assert_equal "Other Team", @other_team.reload.name
  end

  test "duplicate team code is rejected within organization" do
    assert_no_difference("Team.count") do
      post "/api/v1/teams",
           params: {
             team: {
               code: "TEAM-01",
               name: "Duplicate Team"
             }
           },
           headers: {
             "Authorization" => "Bearer #{@token}"
           }
    end

    assert_response :unprocessable_entity

    body = JSON.parse(response.body)

    assert body["messages"].any? { |message| message.include?("Code") }
  end

  test "team name is required" do
    assert_no_difference("Team.count") do
      post "/api/v1/teams",
           params: {
             team: {
               code: "TEAM-INVALID",
               name: ""
             }
           },
           headers: {
             "Authorization" => "Bearer #{@token}"
           }
    end

    assert_response :unprocessable_entity
  end
end