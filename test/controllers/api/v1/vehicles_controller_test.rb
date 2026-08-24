require "test_helper"

class Api::V1::VehiclesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organization = Organization.create!(
      name: "GreenPilot Vehicles Test",
      slug: "greenpilot-vehicles-test"
    )

    @other_organization = Organization.create!(
      name: "Other Vehicles Organization",
      slug: "other-vehicles-org"
    )

    @manager = User.create!(
      organization: @organization,
      email: "manager-vehicles@example.com",
      first_name: "Vehicle",
      last_name: "Manager",
      role: "manager",
      password: "password123",
      password_confirmation: "password123"
    )

    @vehicle = Vehicle.create!(
      organization: @organization,
      name: "Camion Paysage 01",
      registration_number: "AB-123-CD",
      vehicle_type: "truck",
      brand: "Iveco",
      model: "Daily",
      year: 2024,
      fuel_type: "diesel",
      active: true
    )

    @other_vehicle = Vehicle.create!(
      organization: @other_organization,
      name: "Other Organization Vehicle",
      registration_number: "ZZ-999-ZZ",
      vehicle_type: "van",
      brand: "Renault",
      model: "Master",
      active: true
    )

    @token = JwtService.encode(@manager)
  end

  test "index requires authentication" do
    get "/api/v1/vehicles"

    assert_response :unauthorized
  end

  test "index returns vehicles from authenticated user's organization" do
    get "/api/v1/vehicles",
        headers: {
          "Authorization" => "Bearer #{@token}"
        }

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal 1, body.length
    assert_equal @vehicle.id, body.first["id"]
  end

  test "show returns vehicle from same organization" do
    get "/api/v1/vehicles/#{@vehicle.id}",
        headers: {
          "Authorization" => "Bearer #{@token}"
        }

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal @vehicle.id, body["id"]
    assert_equal "Camion Paysage 01", body["name"]
  end

  test "show does not expose vehicle from another organization" do
    get "/api/v1/vehicles/#{@other_vehicle.id}",
        headers: {
          "Authorization" => "Bearer #{@token}"
        }

    assert_response :not_found
  end

  test "manager can create vehicle" do
    assert_difference("Vehicle.count", 1) do
      post "/api/v1/vehicles",
           params: {
             vehicle: {
               name: "Nouveau Fourgon",
               registration_number: "EF-456-GH",
               vehicle_type: "van",
               brand: "Renault",
               model: "Master",
               year: 2025,
               fuel_type: "diesel",
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
    assert_equal "Nouveau Fourgon", body["name"]
    assert_equal "EF-456-GH", body["registration_number"]
  end

  test "manager can update vehicle" do
    patch "/api/v1/vehicles/#{@vehicle.id}",
          params: {
            vehicle: {
              name: "Camion Paysage 02",
              active: false
            }
          },
          headers: {
            "Authorization" => "Bearer #{@token}"
          }

    assert_response :success

    @vehicle.reload

    assert_equal "Camion Paysage 02", @vehicle.name
    assert_equal false, @vehicle.active
  end

  test "manager cannot update vehicle from another organization" do
    patch "/api/v1/vehicles/#{@other_vehicle.id}",
          params: {
            vehicle: {
              name: "Hacked Vehicle"
            }
          },
          headers: {
            "Authorization" => "Bearer #{@token}"
          }

    assert_response :not_found

    assert_equal "Other Organization Vehicle", @other_vehicle.reload.name
  end

  test "duplicate registration number is rejected" do
    assert_no_difference("Vehicle.count") do
      post "/api/v1/vehicles",
           params: {
             vehicle: {
               name: "Duplicate Vehicle",
               registration_number: @vehicle.registration_number,
               vehicle_type: "van"
             }
           },
           headers: {
             "Authorization" => "Bearer #{@token}"
           }
    end

    assert_response :unprocessable_entity
  end

  test "name is required" do
    assert_no_difference("Vehicle.count") do
      post "/api/v1/vehicles",
           params: {
             vehicle: {
               name: "",
               registration_number: "NEW-123-AA"
             }
           },
           headers: {
             "Authorization" => "Bearer #{@token}"
           }
    end

    assert_response :unprocessable_entity
  end

  test "registration number is required" do
    assert_no_difference("Vehicle.count") do
      post "/api/v1/vehicles",
           params: {
             vehicle: {
               name: "Vehicle Without Registration",
               registration_number: ""
             }
           },
           headers: {
             "Authorization" => "Bearer #{@token}"
           }
    end

    assert_response :unprocessable_entity
  end

  test "manager cannot destroy vehicle" do
  assert_no_difference("Vehicle.count") do
    delete "/api/v1/vehicles/#{@vehicle.id}",
           headers: {
             "Authorization" => "Bearer #{@token}"
           }
  end

  assert_response :forbidden

  assert Vehicle.exists?(@vehicle.id)
 end

  test "destroy cannot access vehicle from another organization" do
    assert_no_difference("Vehicle.count") do
      delete "/api/v1/vehicles/#{@other_vehicle.id}",
             headers: {
               "Authorization" => "Bearer #{@token}"
             }
    end

    assert_response :not_found
  end
end