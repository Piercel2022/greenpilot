require "test_helper"

class TeamsApiTest < ActionDispatch::IntegrationTest
  # ============================================================
  # AUTHENTICATION
  # ============================================================

  test "index requires authentication" do
    get "/api/v1/teams"

    assert_response :unauthorized
  end

  test "index rejects invalid token" do
    get "/api/v1/teams",
        headers: {
          "Authorization" => "Bearer invalid-token"
        }

    assert_response :unauthorized
  end

  # ============================================================
  # INDEX
  # ============================================================

  test "authenticated user can list teams" do
    user = users(:member_a)

    get "/api/v1/teams",
        headers: auth_headers(user)

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal 1, body.length
    assert_equal teams(:team_a).id, body.first["id"]
  end

  test "index only returns teams from user's organization" do
    user = users(:member_a)

    get "/api/v1/teams",
        headers: auth_headers(user)

    assert_response :success

    body = JSON.parse(response.body)

    team_ids = body.map { |team| team["id"] }

    assert_includes team_ids, teams(:team_a).id
    assert_not_includes team_ids, teams(:team_b).id
  end

  # ============================================================
  # SHOW
  # ============================================================

  test "user can view team from same organization" do
    user = users(:member_a)
    team = teams(:team_a)

    get "/api/v1/teams/#{team.id}",
        headers: auth_headers(user)

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal team.id, body["id"]
    assert_equal team.code, body["code"]
    assert_equal team.name, body["name"]
  end

  test "user cannot access team from another organization" do
    user = users(:member_a)
    team = teams(:team_b)

    get "/api/v1/teams/#{team.id}",
        headers: auth_headers(user)

    assert_response :not_found
  end

  test "show returns not found for unknown team" do
    user = users(:member_a)

    get "/api/v1/teams/#{SecureRandom.uuid}",
        headers: auth_headers(user)

    assert_response :not_found
  end

  # ============================================================
  # CREATE
  # ============================================================

  test "owner can create team" do
    user = users(:owner_a)

    assert_difference("Team.count", 1) do
      post "/api/v1/teams",
           params: {
             team: {
               code: "TEAM-OWNER-NEW",
               name: "New Owner Team",
               description: "Created by owner",
               color: "#22C55E",
               active: true
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :created

    body = JSON.parse(response.body)

    assert_equal "TEAM-OWNER-NEW", body["code"]
    assert_equal "New Owner Team", body["name"]
    assert_equal user.organization_id, body["organization_id"]
  end

  test "admin can create team" do
    user = users(:admin_a)

    assert_difference("Team.count", 1) do
      post "/api/v1/teams",
           params: {
             team: {
               code: "TEAM-ADMIN-NEW",
               name: "New Admin Team"
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :created
  end

  test "manager can create team" do
    user = users(:manager_a)

    assert_difference("Team.count", 1) do
      post "/api/v1/teams",
           params: {
             team: {
               code: "TEAM-MANAGER-NEW",
               name: "New Manager Team"
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :created
  end

  test "member cannot create team" do
    user = users(:member_a)

    assert_no_difference("Team.count") do
      post "/api/v1/teams",
           params: {
             team: {
               code: "TEAM-MEMBER-NEW",
               name: "Unauthorized Team"
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :forbidden
  end

  test "field worker cannot create team" do
    user = users(:field_worker_a)

    assert_no_difference("Team.count") do
      post "/api/v1/teams",
           params: {
             team: {
               code: "TEAM-FIELD-NEW",
               name: "Unauthorized Team"
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :forbidden
  end

  test "accountant cannot create team" do
    user = users(:accountant_a)

    assert_no_difference("Team.count") do
      post "/api/v1/teams",
           params: {
             team: {
               code: "TEAM-ACCOUNTANT-NEW",
               name: "Unauthorized Team"
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :forbidden
  end

  test "create rejects duplicate code within same organization" do
    user = users(:owner_a)

    assert_no_difference("Team.count") do
      post "/api/v1/teams",
           params: {
             team: {
               code: teams(:team_a).code,
               name: "Duplicate Code Team"
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :unprocessable_entity

    body = JSON.parse(response.body)

    assert_equal "Unprocessable Entity", body["error"]
    assert_includes body["messages"], "Code has already been taken"
  end

  test "create allows same code in another organization" do
    user = users(:owner_a)

    assert_difference("Team.count", 1) do
      post "/api/v1/teams",
           params: {
             team: {
               code: teams(:team_b).code,
               name: "Same Code Different Organization"
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :created

    body = JSON.parse(response.body)

    assert_equal teams(:team_b).code, body["code"]
    assert_equal user.organization_id, body["organization_id"]
  end

  test "create rejects team without code" do
    user = users(:owner_a)

    assert_no_difference("Team.count") do
      post "/api/v1/teams",
           params: {
             team: {
               name: "Team without code"
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :unprocessable_entity

    body = JSON.parse(response.body)

    assert_includes body["messages"], "Code can't be blank"
  end

  test "create rejects team without name" do
    user = users(:owner_a)

    assert_no_difference("Team.count") do
      post "/api/v1/teams",
           params: {
             team: {
               code: "NO-NAME"
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :unprocessable_entity

    body = JSON.parse(response.body)

    assert_includes body["messages"], "Name can't be blank"
  end

  # ============================================================
  # UPDATE
  # ============================================================

  test "owner can update team" do
    user = users(:owner_a)
    team = teams(:team_a)

    patch "/api/v1/teams/#{team.id}",
          params: {
            team: {
              name: "Updated Team",
              description: "Updated through API"
            }
          },
          headers: auth_headers(user),
          as: :json

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal "Updated Team", body["name"]
    assert_equal "Updated through API", body["description"]
  end

  test "admin can update team" do
    user = users(:admin_a)
    team = teams(:team_a)

    patch "/api/v1/teams/#{team.id}",
          params: {
            team: {
              name: "Updated by Admin"
            }
          },
          headers: auth_headers(user),
          as: :json

    assert_response :success
  end

  test "manager can update team" do
    user = users(:manager_a)
    team = teams(:team_a)

    patch "/api/v1/teams/#{team.id}",
          params: {
            team: {
              name: "Updated by Manager"
            }
          },
          headers: auth_headers(user),
          as: :json

    assert_response :success
  end

  test "member cannot update team" do
    user = users(:member_a)
    team = teams(:team_a)

    patch "/api/v1/teams/#{team.id}",
          params: {
            team: {
              name: "Unauthorized Update"
            }
          },
          headers: auth_headers(user),
          as: :json

    assert_response :forbidden
  end

  test "manager cannot update team from another organization" do
    user = users(:manager_a)
    team = teams(:team_b)

    patch "/api/v1/teams/#{team.id}",
          params: {
            team: {
              name: "Unauthorized Cross Organization Update"
            }
          },
          headers: auth_headers(user),
          as: :json

    assert_response :not_found
  end

  # ============================================================
  # DESTROY
  # ============================================================

  test "owner can destroy team without jobs" do
    user = users(:owner_a)

    team = Team.create!(
      organization: organizations(:organization_a),
      code: "TEAM-DELETE-OWNER",
      name: "Team to delete"
    )

    assert_difference("Team.count", -1) do
      delete "/api/v1/teams/#{team.id}",
           headers: auth_headers(user)
    end

    assert_response :no_content
  end

  test "admin can destroy team without jobs" do
    user = users(:admin_a)

    team = Team.create!(
      organization: organizations(:organization_a),
      code: "TEAM-DELETE-ADMIN",
      name: "Team to delete"
    )

    assert_difference("Team.count", -1) do
      delete "/api/v1/teams/#{team.id}",
           headers: auth_headers(user)
    end

    assert_response :no_content
  end

  test "manager cannot destroy team" do
    user = users(:manager_a)
    team = teams(:team_a)

    assert_no_difference("Team.count") do
      delete "/api/v1/teams/#{team.id}",
             headers: auth_headers(user)
    end

    assert_response :forbidden
  end

  test "member cannot destroy team" do
    user = users(:member_a)
    team = teams(:team_a)

    assert_no_difference("Team.count") do
      delete "/api/v1/teams/#{team.id}",
             headers: auth_headers(user)
    end

    assert_response :forbidden
  end

  test "owner cannot destroy team from another organization" do
    user = users(:owner_a)
    team = teams(:team_b)

    assert_no_difference("Team.count") do
      delete "/api/v1/teams/#{team.id}",
             headers: auth_headers(user)
    end

    assert_response :not_found
  end

end