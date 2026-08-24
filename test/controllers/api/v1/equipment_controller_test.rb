require "test_helper"

class Api::V1::EquipmentControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organization = Organization.create!(
      name: "GreenPilot Equipment Test",
      slug: "greenpilot-equipment-test"
    )

    @other_organization = Organization.create!(
      name: "Other Equipment Organization",
      slug: "other-equipment-org"
    )

    @manager = User.create!(
      organization: @organization,
      email: "manager-equipment@example.com",
      first_name: "Equipment",
      last_name: "Manager",
      role: "manager",
      password: "password123",
      password_confirmation: "password123"
    )

    @admin = User.create!(
      organization: @organization,
      email: "admin-equipment@example.com",
      first_name: "Equipment",
      last_name: "Admin",
      role: "admin",
      password: "password123",
      password_confirmation: "password123"
    )

    @equipment = Equipment.create!(
      organization: @organization,
      name: "Tondeuse professionnelle",
      equipment_type: "mower",
      brand: "Honda",
      model: "HRX",
      serial_number: "EQ-SN-001",
      status: "available",
      purchase_date: Date.current,
      purchase_price: 2500.00,
      maintenance_interval_days: 180,
      active: true
    )

    @other_equipment = Equipment.create!(
      organization: @other_organization,
      name: "Other Organization Equipment",
      equipment_type: "mower",
      brand: "Stihl",
      model: "Other",
      serial_number: "OTHER-SN-001",
      status: "available",
      active: true
    )

    @token = JwtService.encode(@manager)
  end

  test "index requires authentication" do
    get "/api/v1/equipment"

    assert_response :unauthorized
  end

  test "index returns equipment from authenticated user's organization" do
    get "/api/v1/equipment",
        headers: {
          "Authorization" => "Bearer #{@token}"
        }

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal 1, body.length
    assert_equal @equipment.id, body.first["id"]
  end

  test "show returns equipment from same organization" do
    get "/api/v1/equipment/#{@equipment.id}",
        headers: {
          "Authorization" => "Bearer #{@token}"
        }

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal @equipment.id, body["id"]
    assert_equal "Tondeuse professionnelle", body["name"]
  end

  test "show does not expose equipment from another organization" do
    get "/api/v1/equipment/#{@other_equipment.id}",
        headers: {
          "Authorization" => "Bearer #{@token}"
        }

    assert_response :not_found
  end

  test "manager can create equipment" do
    assert_difference("Equipment.count", 1) do
      post "/api/v1/equipment",
           params: {
             equipment: {
               name: "Débroussailleuse",
               equipment_type: "brush_cutter",
               brand: "Stihl",
               model: "FS 261",
               serial_number: "EQ-SN-002",
               status: "available",
               purchase_price: 1200.00,
               maintenance_interval_days: 90,
               active: true
             }
           },
           headers: {
             "Authorization" => "Bearer #{@token}"
           }
    end

    assert_response :created

    body = JSON.parse(response.body)

    assert_equal @organization.id, body["organization_id"]
    assert_equal "Débroussailleuse", body["name"]
    assert_equal "available", body["status"]
  end

  test "manager can update equipment" do
    patch "/api/v1/equipment/#{@equipment.id}",
          params: {
            equipment: {
              status: "maintenance",
              purchase_price: 2600.00,
              active: false
            }
          },
          headers: {
            "Authorization" => "Bearer #{@token}"
          }

    assert_response :success

    @equipment.reload

    assert_equal "maintenance", @equipment.status
    assert_equal BigDecimal("2600.00"), @equipment.purchase_price
    assert_equal false, @equipment.active
  end

  test "manager cannot update equipment from another organization" do
    patch "/api/v1/equipment/#{@other_equipment.id}",
          params: {
            equipment: {
              name: "Hacked Equipment"
            }
          },
          headers: {
            "Authorization" => "Bearer #{@token}"
          }

    assert_response :not_found

    assert_equal "Other Organization Equipment",
                 @other_equipment.reload.name
  end

  test "duplicate serial number is rejected within organization" do
    assert_no_difference("Equipment.count") do
      post "/api/v1/equipment",
           params: {
             equipment: {
               name: "Duplicate Equipment",
               equipment_type: "mower",
               serial_number: @equipment.serial_number
             }
           },
           headers: {
             "Authorization" => "Bearer #{@token}"
           }
    end

    assert_response :unprocessable_entity
  end

  test "same serial number is allowed in another organization" do
  other_manager = User.create!(
    organization: @other_organization,
    email: "other-manager-equipment@example.com",
    first_name: "Other",
    last_name: "Manager",
    role: "manager",
    password: "password123",
    password_confirmation: "password123"
  )

  token = JwtService.encode(other_manager)

  assert_difference("Equipment.count", 1) do
    post "/api/v1/equipment",
         params: {
           equipment: {
             name: "Other Organization Serial",
             equipment_type: "mower",
             serial_number: @equipment.serial_number
           }
         },
         headers: {
           "Authorization" => "Bearer #{token}"
         }
  end

  assert_response :created

  body = JSON.parse(response.body)

  assert_equal @other_organization.id, body["organization_id"]
  assert_equal @equipment.serial_number, body["serial_number"]
 end

  test "serial number can be nil" do
    assert_difference("Equipment.count", 1) do
      post "/api/v1/equipment",
           params: {
             equipment: {
               name: "Equipment Without Serial",
               equipment_type: "mower",
               serial_number: nil
             }
           },
           headers: {
             "Authorization" => "Bearer #{@token}"
           }
    end

    assert_response :created
  end

  test "name and equipment type are required" do
    assert_no_difference("Equipment.count") do
      post "/api/v1/equipment",
           params: {
             equipment: {
               name: "",
               equipment_type: ""
             }
           },
           headers: {
             "Authorization" => "Bearer #{@token}"
           }
    end

    assert_response :unprocessable_entity
  end

  test "negative purchase price is rejected" do
    assert_no_difference("Equipment.count") do
      post "/api/v1/equipment",
           params: {
             equipment: {
               name: "Invalid Equipment",
               equipment_type: "mower",
               purchase_price: -100
             }
           },
           headers: {
             "Authorization" => "Bearer #{@token}"
           }
    end

    assert_response :unprocessable_entity
  end

  test "invalid maintenance interval is rejected" do
    assert_no_difference("Equipment.count") do
      post "/api/v1/equipment",
           params: {
             equipment: {
               name: "Invalid Maintenance Equipment",
               equipment_type: "mower",
               maintenance_interval_days: 0
             }
           },
           headers: {
             "Authorization" => "Bearer #{@token}"
           }
    end

    assert_response :unprocessable_entity
  end

  test "manager cannot destroy equipment" do
    assert_no_difference("Equipment.count") do
      delete "/api/v1/equipment/#{@equipment.id}",
             headers: {
               "Authorization" => "Bearer #{@token}"
             }
    end

    assert_response :forbidden
  end

  test "admin can destroy equipment" do
    token = JwtService.encode(@admin)

    assert_difference("Equipment.count", -1) do
      delete "/api/v1/equipment/#{@equipment.id}",
             headers: {
               "Authorization" => "Bearer #{token}"
             }
    end

    assert_response :no_content
  end
end