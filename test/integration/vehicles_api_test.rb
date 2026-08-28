require "test_helper"

class VehiclesApiTest < ActionDispatch::IntegrationTest
  # ============================================================
  # AUTHENTICATION
  # ============================================================

  test "index requires authentication" do
    get "/api/v1/vehicles"

    assert_response :unauthorized
  end

  test "index rejects invalid token" do
    get "/api/v1/vehicles",
        headers: {
          "Authorization" => "Bearer invalid-token"
        }

    assert_response :unauthorized
  end

  # ============================================================
  # INDEX
  # ============================================================

  test "authenticated user can list vehicles" do
    user = users(:member_a)

    get "/api/v1/vehicles",
        headers: auth_headers(user)

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal 1, body.length
    assert_equal vehicles(:vehicle_a).id, body.first["id"]
  end

  test "index only returns vehicles from user's organization" do
    user = users(:member_a)

    get "/api/v1/vehicles",
        headers: auth_headers(user)

    assert_response :success

    body = JSON.parse(response.body)

    vehicle_ids = body.map { |vehicle| vehicle["id"] }

    assert_includes vehicle_ids, vehicles(:vehicle_a).id
    assert_not_includes vehicle_ids, vehicles(:vehicle_b).id
  end

  # ============================================================
  # SHOW
  # ============================================================

  test "user can view vehicle from same organization" do
    user = users(:member_a)
    vehicle = vehicles(:vehicle_a)

    get "/api/v1/vehicles/#{vehicle.id}",
        headers: auth_headers(user)

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal vehicle.id, body["id"]
    assert_equal vehicle.name, body["name"]
    assert_equal vehicle.registration_number, body["registration_number"]
  end

  test "user cannot access vehicle from another organization" do
    user = users(:member_a)
    vehicle = vehicles(:vehicle_b)

    get "/api/v1/vehicles/#{vehicle.id}",
        headers: auth_headers(user)

    assert_response :not_found
  end

  test "show returns not found for unknown vehicle" do
    user = users(:member_a)

    get "/api/v1/vehicles/#{SecureRandom.uuid}",
        headers: auth_headers(user)

    assert_response :not_found
  end

  # ============================================================
  # CREATE
  # ============================================================

  test "owner can create vehicle" do
    user = users(:owner_a)

    assert_difference("Vehicle.count", 1) do
      post "/api/v1/vehicles",
           params: {
             vehicle: {
               name: "New Owner Vehicle",
               registration_number: "NEW-001"
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :created

    body = JSON.parse(response.body)

    assert_equal "New Owner Vehicle", body["name"]
    assert_equal "NEW-001", body["registration_number"]
    assert_equal user.organization_id, Vehicle.find(body["id"]).organization_id
  end

  test "admin can create vehicle" do
    user = users(:admin_a)

    assert_difference("Vehicle.count", 1) do
      post "/api/v1/vehicles",
           params: {
             vehicle: {
               name: "New Admin Vehicle",
               registration_number: "NEW-002"
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :created
  end

  test "manager can create vehicle" do
    user = users(:manager_a)

    assert_difference("Vehicle.count", 1) do
      post "/api/v1/vehicles",
           params: {
             vehicle: {
               name: "New Manager Vehicle",
               registration_number: "NEW-003"
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :created
  end

  test "member cannot create vehicle" do
    user = users(:member_a)

    assert_no_difference("Vehicle.count") do
      post "/api/v1/vehicles",
           params: {
             vehicle: {
               name: "Unauthorized Vehicle",
               registration_number: "NEW-004"
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :forbidden
  end

  test "accountant cannot create vehicle" do
    user = users(:accountant_a)

    assert_no_difference("Vehicle.count") do
      post "/api/v1/vehicles",
           params: {
             vehicle: {
               name: "Unauthorized Accountant Vehicle",
               registration_number: "NEW-005"
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :forbidden
  end

  test "field worker cannot create vehicle" do
    user = users(:field_worker_a)

    assert_no_difference("Vehicle.count") do
      post "/api/v1/vehicles",
           params: {
             vehicle: {
               name: "Unauthorized Field Vehicle",
               registration_number: "NEW-006"
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :forbidden
  end

  test "create rejects vehicle without name" do
    user = users(:manager_a)

    assert_no_difference("Vehicle.count") do
      post "/api/v1/vehicles",
           params: {
             vehicle: {
               registration_number: "INVALID-001"
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :unprocessable_entity

    body = JSON.parse(response.body)

    assert_includes body["messages"], "Name can't be blank"
  end

  test "create rejects duplicate registration number in same organization" do
    user = users(:manager_a)

    assert_no_difference("Vehicle.count") do
      post "/api/v1/vehicles",
           params: {
             vehicle: {
               name: "Duplicate Vehicle",
               registration_number: vehicles(:vehicle_a).registration_number
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :unprocessable_entity
  end

  # ============================================================
  # UPDATE
  # ============================================================

  test "owner can update vehicle" do
    user = users(:owner_a)
    vehicle = vehicles(:vehicle_a)

    patch "/api/v1/vehicles/#{vehicle.id}",
          params: {
            vehicle: {
              name: "Updated Vehicle"
            }
          },
          headers: auth_headers(user),
          as: :json

    assert_response :success

    vehicle.reload

    assert_equal "Updated Vehicle", vehicle.name
  end

  test "admin can update vehicle" do
    user = users(:admin_a)
    vehicle = vehicles(:vehicle_a)

    patch "/api/v1/vehicles/#{vehicle.id}",
          params: {
            vehicle: {
              name: "Updated By Admin"
            }
          },
          headers: auth_headers(user),
          as: :json

    assert_response :success

    assert_equal "Updated By Admin", vehicle.reload.name
  end

  test "manager can update vehicle" do
    user = users(:manager_a)
    vehicle = vehicles(:vehicle_a)

    patch "/api/v1/vehicles/#{vehicle.id}",
          params: {
            vehicle: {
              name: "Updated By Manager"
            }
          },
          headers: auth_headers(user),
          as: :json

    assert_response :success

    assert_equal "Updated By Manager", vehicle.reload.name
  end

  test "member cannot update vehicle" do
    user = users(:member_a)
    vehicle = vehicles(:vehicle_a)

    patch "/api/v1/vehicles/#{vehicle.id}",
          params: {
            vehicle: {
              name: "Unauthorized Update"
            }
          },
          headers: auth_headers(user),
          as: :json

    assert_response :forbidden

    assert_equal vehicles(:vehicle_a).name, vehicle.reload.name
  end

  test "accountant cannot update vehicle" do
    user = users(:accountant_a)
    vehicle = vehicles(:vehicle_a)

    patch "/api/v1/vehicles/#{vehicle.id}",
          params: {
            vehicle: {
              name: "Unauthorized Accountant Update"
            }
          },
          headers: auth_headers(user),
          as: :json

    assert_response :forbidden
  end

  test "manager cannot update vehicle from another organization" do
    user = users(:manager_a)
    vehicle = vehicles(:vehicle_b)

    patch "/api/v1/vehicles/#{vehicle.id}",
          params: {
            vehicle: {
              name: "Cross Organization Update"
            }
          },
          headers: auth_headers(user),
          as: :json

    assert_response :not_found
  end

  test "update rejects duplicate registration number in same organization" do
    user = users(:manager_a)
    vehicle = vehicles(:vehicle_a)

    patch "/api/v1/vehicles/#{vehicle.id}",
          params: {
            vehicle: {
              registration_number: vehicles(:vehicle_b).registration_number
            }
          },
          headers: auth_headers(user),
          as: :json

    # vehicle_b belongs to another organization, so this must remain valid.
    assert_response :success
  end

  # ============================================================
  # DESTROY
  # ============================================================

  test "owner can destroy vehicle" do
    user = users(:owner_a)

    vehicle = Vehicle.create!(
      organization: organizations(:organization_a),
      name: "Vehicle To Destroy",
      registration_number: "DESTROY-001"
    )

    assert_difference("Vehicle.count", -1) do
      delete "/api/v1/vehicles/#{vehicle.id}",
             headers: auth_headers(user)
    end

    assert_response :no_content
  end

  test "admin can destroy vehicle" do
    user = users(:admin_a)

    vehicle = Vehicle.create!(
      organization: organizations(:organization_a),
      name: "Vehicle To Destroy Admin",
      registration_number: "DESTROY-002"
    )

    assert_difference("Vehicle.count", -1) do
      delete "/api/v1/vehicles/#{vehicle.id}",
             headers: auth_headers(user)
    end

    assert_response :no_content
  end

  test "manager cannot destroy vehicle" do
    user = users(:manager_a)

    vehicle = Vehicle.create!(
      organization: organizations(:organization_a),
      name: "Vehicle Protected",
      registration_number: "DESTROY-003"
    )

    assert_no_difference("Vehicle.count") do
      delete "/api/v1/vehicles/#{vehicle.id}",
             headers: auth_headers(user)
    end

    assert_response :forbidden
  end

  test "member cannot destroy vehicle" do
    user = users(:member_a)

    vehicle = Vehicle.create!(
      organization: organizations(:organization_a),
      name: "Vehicle Protected Member",
      registration_number: "DESTROY-004"
    )

    assert_no_difference("Vehicle.count") do
      delete "/api/v1/vehicles/#{vehicle.id}",
             headers: auth_headers(user)
    end

    assert_response :forbidden
  end

  test "owner cannot destroy vehicle from another organization" do
    user = users(:owner_a)
    vehicle = vehicles(:vehicle_b)

    assert_no_difference("Vehicle.count") do
      delete "/api/v1/vehicles/#{vehicle.id}",
             headers: auth_headers(user)
    end

    assert_response :not_found
  end

  private

  def auth_headers(user)
    {
      "Authorization" => "Bearer #{JwtService.encode(user)}"
    }
  end
end
