require "test_helper"

class Api::V1::ServiceItemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organization = Organization.create!(
      name: "GreenPilot Service Items Test",
      slug: "greenpilot-service-items-test"
    )

    @other_organization = Organization.create!(
      name: "Other Service Items Organization",
      slug: "other-service-items-org"
    )

    @manager = User.create!(
      organization: @organization,
      email: "manager-service-items@example.com",
      first_name: "Service",
      last_name: "Item Manager",
      role: "manager",
      password: "password123",
      password_confirmation: "password123"
    )

    @category = ServiceCategory.create!(
      organization: @organization,
      code: "ENT",
      name: "Entretien",
      position: 1,
      active: true
    )

    @second_category = ServiceCategory.create!(
      organization: @organization,
      code: "CRE",
      name: "Création",
      position: 2,
      active: true
    )

    @other_category = ServiceCategory.create!(
      organization: @other_organization,
      code: "OTH",
      name: "Other Services",
      position: 1,
      active: true
    )

    @service_item = ServiceItem.create!(
      organization: @organization,
      service_category: @category,
      code: "TONTE",
      name: "Tonte de pelouse",
      description: "Tonte classique",
      default_quantity: 1.0,
      default_unit_price: 45.0,
      default_margin_percentage: 30.0,
      labor_cost: 20.0,
      material_cost: 2.0,
      equipment_cost: 5.0,
      overhead_cost: 3.0,
      estimated_duration_minutes: 60,
      unit: "hour",
      position: 1,
      active: true
    )

    @other_service_item = ServiceItem.create!(
      organization: @other_organization,
      service_category: @other_category,
      code: "OTHER",
      name: "Other Service",
      position: 1,
      active: true
    )

    @token = JwtService.encode(@manager)
  end

  test "index requires authentication" do
    get "/api/v1/service_items"

    assert_response :unauthorized
  end

  test "index returns service items from authenticated user's organization" do
    second_item = ServiceItem.create!(
      organization: @organization,
      service_category: @second_category,
      code: "TAILLE",
      name: "Taille de haies",
      position: 2
    )

    get "/api/v1/service_items",
        headers: {
          "Authorization" => "Bearer #{@token}"
        }

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal 2, body.length
    assert_equal @service_item.id, body.first["id"]
    assert_equal second_item.id, body.second["id"]
  end

  test "show returns service item from same organization" do
    get "/api/v1/service_items/#{@service_item.id}",
        headers: {
          "Authorization" => "Bearer #{@token}"
        }

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal @service_item.id, body["id"]
    assert_equal "TONTE", body["code"]
    assert_equal @category.id, body["service_category_id"]
  end

  test "show does not expose service item from another organization" do
    get "/api/v1/service_items/#{@other_service_item.id}",
        headers: {
          "Authorization" => "Bearer #{@token}"
        }

    assert_response :not_found
  end

  test "manager can create service item" do
    assert_difference("ServiceItem.count", 1) do
      post "/api/v1/service_items",
           params: {
             service_item: {
               service_category_id: @category.id,
               code: "DEBROUS",
               name: "Débroussaillage",
               description: "Débroussaillage des espaces verts",
               default_quantity: 1.0,
               default_unit_price: 75.0,
               default_margin_percentage: 30.0,
               labor_cost: 30.0,
               material_cost: 5.0,
               equipment_cost: 10.0,
               overhead_cost: 5.0,
               estimated_duration_minutes: 90,
               unit: "hour",
               position: 2,
               active: true
             }
           },
           headers: {
             "Authorization" => "Bearer #{@token}"
           }
    end

    assert_response :created

    body = JSON.parse(response.body)

    assert_equal "DEBROUS", body["code"]
    assert_equal "Débroussaillage", body["name"]
    assert_equal @category.id, body["service_category_id"]
    assert_equal @organization.id, body["organization_id"]
  end

  test "manager cannot create service item with category from another organization" do
    assert_no_difference("ServiceItem.count") do
      post "/api/v1/service_items",
           params: {
             service_item: {
               service_category_id: @other_category.id,
               code: "HACK",
               name: "Invalid Service Item"
             }
           },
           headers: {
             "Authorization" => "Bearer #{@token}"
           }
    end

    assert_response :forbidden
  end

  test "manager can update service item" do
    patch "/api/v1/service_items/#{@service_item.id}",
          params: {
            service_item: {
              name: "Tonte professionnelle",
              default_unit_price: 55.0,
              estimated_duration_minutes: 75
            }
          },
          headers: {
            "Authorization" => "Bearer #{@token}"
          }

    assert_response :success

    @service_item.reload

    assert_equal "Tonte professionnelle", @service_item.name
    assert_equal 55.0, @service_item.default_unit_price.to_f
    assert_equal 75, @service_item.estimated_duration_minutes
  end

  test "manager cannot update service item from another organization" do
    patch "/api/v1/service_items/#{@other_service_item.id}",
          params: {
            service_item: {
              name: "Unauthorized update"
            }
          },
          headers: {
            "Authorization" => "Bearer #{@token}"
          }

    assert_response :not_found

    assert_equal "Other Service", @other_service_item.reload.name
  end

  test "duplicate code is rejected within organization" do
    assert_no_difference("ServiceItem.count") do
      post "/api/v1/service_items",
           params: {
             service_item: {
               service_category_id: @category.id,
               code: "TONTE",
               name: "Tonte duplicate"
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
end