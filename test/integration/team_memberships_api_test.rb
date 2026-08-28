require "test_helper"

class TeamMembershipsApiTest < ActionDispatch::IntegrationTest
  # ============================================================
  # AUTHENTICATION
  # ============================================================

  test "index requires authentication" do
    get "/api/v1/team_memberships"

    assert_response :unauthorized
  end

  test "index rejects invalid token" do
    get "/api/v1/team_memberships",
        headers: {
          "Authorization" => "Bearer invalid-token"
        }

    assert_response :unauthorized
  end

  # ============================================================
  # INDEX
  # ============================================================

  test "authenticated user can list team memberships" do
    user = users(:member_a)

    get "/api/v1/team_memberships",
        headers: auth_headers(user)

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal 1, body.length
  end

  test "index only returns memberships from user's organization" do
    user = users(:member_a)

    get "/api/v1/team_memberships",
        headers: auth_headers(user)

    assert_response :success

    body = JSON.parse(response.body)

    membership_ids = body.map { |membership| membership["id"] }

    assert_includes membership_ids, team_memberships(:membership_a).id
    assert_not_includes membership_ids, team_memberships(:membership_b).id
  end

  # ============================================================
  # SHOW
  # ============================================================

  test "user can view membership from same organization" do
    user = users(:member_a)
    membership = team_memberships(:membership_a)

    get "/api/v1/team_memberships/#{membership.id}",
        headers: auth_headers(user)

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal membership.id, body["id"]
    assert_equal membership.team_id, body["team_id"]
    assert_equal membership.user_id, body["user_id"]
    assert_equal membership.organization_id, body["organization_id"]
  end

  test "user cannot access membership from another organization" do
    user = users(:member_a)
    membership = team_memberships(:membership_b)

    get "/api/v1/team_memberships/#{membership.id}",
        headers: auth_headers(user)

    assert_response :not_found
  end

  test "show returns not found for unknown membership" do
    user = users(:member_a)

    get "/api/v1/team_memberships/#{SecureRandom.uuid}",
        headers: auth_headers(user)

    assert_response :not_found
  end

  # ============================================================
  # CREATE
  # ============================================================

  test "owner can create team membership" do
    user = users(:owner_a)

    new_user = User.create!(
      organization: organizations(:organization_a),
      email: "new-member-owner@example.test",
      first_name: "New",
      last_name: "Member",
      password: "password",
      password_confirmation: "password",
      role: "member"
    )

    assert_difference("TeamMembership.count", 1) do
      post "/api/v1/team_memberships",
         params: {
           team_membership: {
             team_id: teams(:team_a).id,
             user_id: new_user.id,
             role: "member",
             active: true
           }
         },
         headers: auth_headers(user),
         as: :json
    end

    assert_response :created

    body = JSON.parse(response.body)

    assert_equal teams(:team_a).id, body["team_id"]
    assert_equal new_user.id, body["user_id"]
  end
  
  test "admin can create team membership" do
    user = users(:admin_a)

    new_user = User.create!(
      organization: organizations(:organization_a),
      email: "new-member-admin@example.test",
      first_name: "New",
      last_name: "Member",
      password: "password",
      password_confirmation: "password",
      role: "member"
    )

    assert_difference("TeamMembership.count", 1) do
      post "/api/v1/team_memberships",
           params: {
             team_membership: {
               team_id: teams(:team_a).id,
               user_id: new_user.id,
               role: "member"
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :created
  end

  test "manager can create team membership" do
    user = users(:manager_a)

    new_user = User.create!(
      organization: organizations(:organization_a),
      email: "new-member-manager@example.test",
      first_name: "New",
      last_name: "Member",
      password: "password",
      password_confirmation: "password",
      role: "member"
    )

    assert_difference("TeamMembership.count", 1) do
      post "/api/v1/team_memberships",
           params: {
             team_membership: {
               team_id: teams(:team_a).id,
               user_id: new_user.id,
               role: "member"
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :created
  end

  test "member cannot create team membership" do
    user = users(:member_a)

    assert_no_difference("TeamMembership.count") do
      post "/api/v1/team_memberships",
           params: {
             team_membership: {
               team_id: teams(:team_a).id,
               user_id: users(:member_a).id,
               role: "member"
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :forbidden
  end

  test "accountant cannot create team membership" do
    user = users(:accountant_a)

    assert_no_difference("TeamMembership.count") do
      post "/api/v1/team_memberships",
           params: {
             team_membership: {
               team_id: teams(:team_a).id,
               user_id: users(:member_a).id,
               role: "member"
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :forbidden
  end

  
  test "manager cannot create membership with foreign team" do
    user = users(:manager_a)

    new_user = User.create!(
      organization: organizations(:organization_a),
      email: "foreign-team-user@example.test",
      first_name: "Foreign",
      last_name: "Team",
      password: "password",
      password_confirmation: "password",
      role: "member"
    )

    assert_no_difference("TeamMembership.count") do
      post "/api/v1/team_memberships",
         params: {
           team_membership: {
             team_id: teams(:team_b).id,
             user_id: new_user.id,
             role: "member"
           }
         },
         headers: auth_headers(user),
         as: :json
    end

    assert_response :forbidden
  end


  
  test "manager cannot create membership with foreign user" do
    user = users(:manager_a)

    assert_no_difference("TeamMembership.count") do
      post "/api/v1/team_memberships",
         params: {
           team_membership: {
             team_id: teams(:team_a).id,
             user_id: users(:member_b).id,
             role: "member"
           }
         },
         headers: auth_headers(user),
         as: :json
    end

    assert_response :forbidden
  end

    # ============================================================
  # UPDATE
  # ============================================================

  test "owner can update team membership" do
    user = users(:owner_a)
    membership = team_memberships(:membership_a)

    patch "/api/v1/team_memberships/#{membership.id}",
          params: {
            team_membership: {
              role: "manager",
              active: false
            }
          },
          headers: auth_headers(user),
          as: :json

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal membership.id, body["id"]
    assert_equal "manager", body["role"]
    assert_equal false, body["active"]

    membership.reload
    assert_equal "manager", membership.role
    assert_not membership.active
  end

  test "admin can update team membership" do
    user = users(:admin_a)
    membership = team_memberships(:membership_a)

    patch "/api/v1/team_memberships/#{membership.id}",
          params: {
            team_membership: {
              role: "field_worker"
            }
          },
          headers: auth_headers(user),
          as: :json

    assert_response :success

    membership.reload

    assert_equal "field_worker", membership.role
  end

  test "manager can update team membership" do
    user = users(:manager_a)
    membership = team_memberships(:membership_a)

    patch "/api/v1/team_memberships/#{membership.id}",
          params: {
            team_membership: {
              active: false
            }
          },
          headers: auth_headers(user),
          as: :json

    assert_response :success

    membership.reload

    assert_not membership.active
  end

  test "member cannot update team membership" do
    user = users(:member_a)
    membership = team_memberships(:membership_a)

    assert_no_changes -> { membership.reload.role } do
      patch "/api/v1/team_memberships/#{membership.id}",
            params: {
              team_membership: {
                role: "manager"
              }
            },
            headers: auth_headers(user),
            as: :json
    end

    assert_response :forbidden
  end

  test "accountant cannot update team membership" do
    user = users(:accountant_a)
    membership = team_memberships(:membership_a)

    assert_no_changes -> { membership.reload.role } do
      patch "/api/v1/team_memberships/#{membership.id}",
            params: {
              team_membership: {
                role: "manager"
              }
            },
            headers: auth_headers(user),
            as: :json
    end

    assert_response :forbidden
  end

  test "field worker cannot update team membership" do
    user = users(:field_worker_a)
    membership = team_memberships(:membership_a)

    assert_no_changes -> { membership.reload.role } do
      patch "/api/v1/team_memberships/#{membership.id}",
            params: {
              team_membership: {
                role: "manager"
              }
            },
            headers: auth_headers(user),
            as: :json
    end

    assert_response :forbidden
  end

  # ============================================================
  # UPDATE — TENANT ISOLATION
  # ============================================================

  test "manager cannot update membership from another organization" do
    user = users(:manager_a)
    membership = team_memberships(:membership_b)

    patch "/api/v1/team_memberships/#{membership.id}",
          params: {
            team_membership: {
              role: "manager"
            }
          },
          headers: auth_headers(user),
          as: :json

    assert_response :not_found
  end

  test "manager cannot update membership with foreign team" do
    user = users(:manager_a)
    membership = team_memberships(:membership_a)

    patch "/api/v1/team_memberships/#{membership.id}",
          params: {
            team_membership: {
              team_id: teams(:team_b).id
            }
          },
          headers: auth_headers(user),
          as: :json

    assert_response :unprocessable_entity

    body = JSON.parse(response.body)

    assert_includes body["messages"],
                "Team must belong to the same organization"
  end

  test "manager cannot update membership with foreign user" do
    user = users(:manager_a)
    membership = team_memberships(:membership_a)

    patch "/api/v1/team_memberships/#{membership.id}",
          params: {
            team_membership: {
              user_id: users(:member_b).id
            }
          },
          headers: auth_headers(user),
          as: :json

    assert_response :unprocessable_entity

    body = JSON.parse(response.body)

    assert_includes body["messages"],
                "User must belong to the same organization"
  end

    # ============================================================
  # DESTROY
  # ============================================================

  test "owner can destroy team membership" do
    user = users(:owner_a)
    membership = team_memberships(:membership_a)

    assert_difference("TeamMembership.count", -1) do
      delete "/api/v1/team_memberships/#{membership.id}",
             headers: auth_headers(user)
    end

    assert_response :no_content
  end

  test "admin can destroy team membership" do
    user = users(:admin_a)
    membership = team_memberships(:membership_a)

    assert_difference("TeamMembership.count", -1) do
      delete "/api/v1/team_memberships/#{membership.id}",
             headers: auth_headers(user)
    end

    assert_response :no_content
  end

  test "manager can destroy team membership" do
    user = users(:manager_a)
    membership = team_memberships(:membership_a)

    assert_difference("TeamMembership.count", -1) do
      delete "/api/v1/team_memberships/#{membership.id}",
             headers: auth_headers(user)
    end

    assert_response :no_content
  end

  test "member cannot destroy team membership" do
    user = users(:member_a)
    membership = team_memberships(:membership_a)

    assert_no_difference("TeamMembership.count") do
      delete "/api/v1/team_memberships/#{membership.id}",
             headers: auth_headers(user)
    end

    assert_response :forbidden
  end

  test "accountant cannot destroy team membership" do
    user = users(:accountant_a)
    membership = team_memberships(:membership_a)

    assert_no_difference("TeamMembership.count") do
      delete "/api/v1/team_memberships/#{membership.id}",
             headers: auth_headers(user)
    end

    assert_response :forbidden
  end

  test "field worker cannot destroy team membership" do
    user = users(:field_worker_a)
    membership = team_memberships(:membership_a)

    assert_no_difference("TeamMembership.count") do
      delete "/api/v1/team_memberships/#{membership.id}",
             headers: auth_headers(user)
    end

    assert_response :forbidden
  end

  # ============================================================
  # DESTROY — TENANT ISOLATION
  # ============================================================

  test "manager cannot destroy membership from another organization" do
    user = users(:manager_a)
    membership = team_memberships(:membership_b)

    assert_no_difference("TeamMembership.count") do
      delete "/api/v1/team_memberships/#{membership.id}",
             headers: auth_headers(user)
    end

    assert_response :not_found
  end

end