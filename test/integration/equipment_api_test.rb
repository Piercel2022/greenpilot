require "test_helper"

class EquipmentApiTest < ActionDispatch::IntegrationTest
  # ============================================================
  # AUTHENTICATION
  # ============================================================

  test "index requires authentication" do
    get "/api/v1/equipment"

    assert_response :unauthorized
  end

  test "index rejects invalid token" do
    get "/api/v1/equipment",
        headers: {
          "Authorization" => "Bearer invalid-token"
        }

    assert_response :unauthorized
  end

  # ============================================================
  # INDEX
  # ============================================================

  test "authenticated user can list equipment" do
    user = users(:member_a)

    get "/api/v1/equipment",
        headers: auth_headers(user)

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal 1, body.length
    assert_equal equipment(:equipment_a).id, body.first["id"]
  end

  test "index only returns equipment from user's organization" do
    user = users(:member_a)

    get "/api/v1/equipment",
        headers: auth_headers(user)

    assert_response :success

    body = JSON.parse(response.body)

    equipment_ids = body.map { |item| item["id"] }

    assert_includes equipment_ids, equipment(:equipment_a).id
    assert_not_includes equipment_ids, equipment(:equipment_b).id
  end

  # ============================================================
  # SHOW
  # ============================================================

  test "user can view equipment from same organization" do
    user = users(:member_a)
    item = equipment(:equipment_a)

    get "/api/v1/equipment/#{item.id}",
        headers: auth_headers(user)

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal item.id, body["id"]
    assert_equal item.name, body["name"]
    assert_equal item.equipment_type, body["equipment_type"]
    assert_equal item.status, body["status"]
  end

  test "user cannot access equipment from another organization" do
    user = users(:member_a)
    item = equipment(:equipment_b)

    get "/api/v1/equipment/#{item.id}",
        headers: auth_headers(user)

    assert_response :not_found
  end

  test "show returns not found for unknown equipment" do
    user = users(:member_a)

    get "/api/v1/equipment/#{SecureRandom.uuid}",
        headers: auth_headers(user)

    assert_response :not_found
  end

  # ============================================================
  # CREATE
  # ============================================================

  test "owner can create equipment" do
    user = users(:owner_a)

    assert_difference("Equipment.count", 1) do
      post "/api/v1/equipment",
           params: {
             equipment: {
               name: "New Owner Equipment",
               equipment_type: "mower",
               status: "available"
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :created

    body = JSON.parse(response.body)

    assert_equal "New Owner Equipment", body["name"]
    assert_equal "mower", body["equipment_type"]
    assert_equal "available", body["status"]
    assert_equal user.organization_id,
                 Equipment.find(body["id"]).organization_id
  end

  test "admin can create equipment" do
    user = users(:admin_a)

    assert_difference("Equipment.count", 1) do
      post "/api/v1/equipment",
           params: {
             equipment: {
               name: "New Admin Equipment",
               equipment_type: "blower",
               status: "available"
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :created
  end

  test "manager can create equipment" do
    user = users(:manager_a)

    assert_difference("Equipment.count", 1) do
      post "/api/v1/equipment",
           params: {
             equipment: {
               name: "New Manager Equipment",
               equipment_type: "trimmer",
               status: "available"
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :created
  end

  test "member cannot create equipment" do
    user = users(:member_a)

    assert_no_difference("Equipment.count") do
      post "/api/v1/equipment",
           params: {
             equipment: {
               name: "Unauthorized Equipment",
               equipment_type: "mower"
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :forbidden
  end

  test "accountant cannot create equipment" do
    user = users(:accountant_a)

    assert_no_difference("Equipment.count") do
      post "/api/v1/equipment",
           params: {
             equipment: {
               name: "Unauthorized Accountant Equipment",
               equipment_type: "mower"
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :forbidden
  end

  test "field worker cannot create equipment" do
    user = users(:field_worker_a)

    assert_no_difference("Equipment.count") do
      post "/api/v1/equipment",
           params: {
             equipment: {
               name: "Unauthorized Field Equipment",
               equipment_type: "mower"
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :forbidden
  end

  test "create rejects equipment without name" do
    user = users(:manager_a)

    assert_no_difference("Equipment.count") do
      post "/api/v1/equipment",
           params: {
             equipment: {
               equipment_type: "mower"
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :unprocessable_entity

    body = JSON.parse(response.body)

    assert_includes body["messages"], "Name can't be blank"
  end

  test "create rejects equipment without equipment type" do
    user = users(:manager_a)

    assert_no_difference("Equipment.count") do
      post "/api/v1/equipment",
           params: {
             equipment: {
               name: "Equipment Without Type"
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :unprocessable_entity

    body = JSON.parse(response.body)

    assert_includes body["messages"], "Equipment type can't be blank"
  end

  test "create rejects negative purchase price" do
    user = users(:manager_a)

    assert_no_difference("Equipment.count") do
      post "/api/v1/equipment",
           params: {
             equipment: {
               name: "Invalid Equipment",
               equipment_type: "mower",
               purchase_price: -1
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :unprocessable_entity
  end

  test "create rejects non-positive maintenance interval" do
    user = users(:manager_a)

    assert_no_difference("Equipment.count") do
      post "/api/v1/equipment",
           params: {
             equipment: {
               name: "Invalid Maintenance Equipment",
               equipment_type: "mower",
               maintenance_interval_days: 0
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :unprocessable_entity
  end

  test "create rejects duplicate serial number in same organization" do
    user = users(:manager_a)

    assert_no_difference("Equipment.count") do
      post "/api/v1/equipment",
           params: {
             equipment: {
               name: "Duplicate Serial Equipment",
               equipment_type: "mower",
               serial_number: equipment(:equipment_a).serial_number
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

  test "owner can update equipment" do
    user = users(:owner_a)
    item = equipment(:equipment_a)

    patch "/api/v1/equipment/#{item.id}",
          params: {
            equipment: {
              name: "Updated Equipment"
            }
          },
          headers: auth_headers(user),
          as: :json

    assert_response :success

    assert_equal "Updated Equipment", item.reload.name
  end

  test "admin can update equipment" do
    user = users(:admin_a)
    item = equipment(:equipment_a)

    patch "/api/v1/equipment/#{item.id}",
          params: {
            equipment: {
              name: "Updated By Admin"
            }
          },
          headers: auth_headers(user),
          as: :json

    assert_response :success

    assert_equal "Updated By Admin", item.reload.name
  end

  test "manager can update equipment" do
    user = users(:manager_a)
    item = equipment(:equipment_a)

    patch "/api/v1/equipment/#{item.id}",
          params: {
            equipment: {
              name: "Updated By Manager"
            }
          },
          headers: auth_headers(user),
          as: :json

    assert_response :success

    assert_equal "Updated By Manager", item.reload.name
  end

  test "member cannot update equipment" do
    user = users(:member_a)
    item = equipment(:equipment_a)
    original_name = item.name

    patch "/api/v1/equipment/#{item.id}",
          params: {
            equipment: {
              name: "Unauthorized Update"
            }
          },
          headers: auth_headers(user),
          as: :json

    assert_response :forbidden

    assert_equal original_name, item.reload.name
  end

  test "accountant cannot update equipment" do
    user = users(:accountant_a)
    item = equipment(:equipment_a)

    patch "/api/v1/equipment/#{item.id}",
          params: {
            equipment: {
              name: "Unauthorized Accountant Update"
            }
          },
          headers: auth_headers(user),
          as: :json

    assert_response :forbidden
  end

  test "field worker cannot update equipment" do
    user = users(:field_worker_a)
    item = equipment(:equipment_a)

    patch "/api/v1/equipment/#{item.id}",
          params: {
            equipment: {
              name: "Unauthorized Field Update"
            }
          },
          headers: auth_headers(user),
          as: :json

    assert_response :forbidden
  end

  test "manager cannot update equipment from another organization" do
    user = users(:manager_a)
    item = equipment(:equipment_b)

    patch "/api/v1/equipment/#{item.id}",
          params: {
            equipment: {
              name: "Cross Organization Update"
            }
          },
          headers: auth_headers(user),
          as: :json

    assert_response :not_found
  end

  test "update can change equipment status" do
    user = users(:manager_a)
    item = equipment(:equipment_a)

    patch "/api/v1/equipment/#{item.id}",
          params: {
            equipment: {
              status: "maintenance"
            }
          },
          headers: auth_headers(user),
          as: :json

    assert_response :success

    assert_equal "maintenance", item.reload.status
  end

  test "update rejects negative purchase price" do
    user = users(:manager_a)
    item = equipment(:equipment_a)

    patch "/api/v1/equipment/#{item.id}",
          params: {
            equipment: {
              purchase_price: -1
            }
          },
          headers: auth_headers(user),
          as: :json

    assert_response :unprocessable_entity
  end

  test "update rejects non-positive maintenance interval" do
    user = users(:manager_a)
    item = equipment(:equipment_a)

    patch "/api/v1/equipment/#{item.id}",
          params: {
            equipment: {
              maintenance_interval_days: 0
            }
          },
          headers: auth_headers(user),
          as: :json

    assert_response :unprocessable_entity
  end

  # ============================================================
  # DESTROY
  # ============================================================

  test "owner can destroy equipment" do
    user = users(:owner_a)

    item = Equipment.create!(
      organization: organizations(:organization_a),
      name: "Equipment To Destroy",
      equipment_type: "mower"
    )

    assert_difference("Equipment.count", -1) do
      delete "/api/v1/equipment/#{item.id}",
             headers: auth_headers(user)
    end

    assert_response :no_content
  end

  test "admin can destroy equipment" do
    user = users(:admin_a)

    item = Equipment.create!(
      organization: organizations(:organization_a),
      name: "Equipment To Destroy Admin",
      equipment_type: "blower"
    )

    assert_difference("Equipment.count", -1) do
      delete "/api/v1/equipment/#{item.id}",
             headers: auth_headers(user)
    end

    assert_response :no_content
  end

  test "manager cannot destroy equipment" do
    user = users(:manager_a)

    item = Equipment.create!(
      organization: organizations(:organization_a),
      name: "Protected Equipment",
      equipment_type: "mower"
    )

    assert_no_difference("Equipment.count") do
      delete "/api/v1/equipment/#{item.id}",
             headers: auth_headers(user)
    end

    assert_response :forbidden
  end

  test "member cannot destroy equipment" do
    user = users(:member_a)

    item = Equipment.create!(
      organization: organizations(:organization_a),
      name: "Protected Member Equipment",
      equipment_type: "mower"
    )

    assert_no_difference("Equipment.count") do
      delete "/api/v1/equipment/#{item.id}",
             headers: auth_headers(user)
    end

    assert_response :forbidden
  end

  test "owner cannot destroy equipment from another organization" do
    user = users(:owner_a)
    item = equipment(:equipment_b)

    assert_no_difference("Equipment.count") do
      delete "/api/v1/equipment/#{item.id}",
             headers: auth_headers(user)
    end

    assert_response :not_found
  end
end
