require "test_helper"

class Api::V1::ServiceCategoriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organization = Organization.create!(
      name: "GreenPilot Service Categories Test",
      slug: "greenpilot-service-categories-test"
    )

    @other_organization = Organization.create!(
      name: "Other Service Categories Organization",
      slug: "other-service-categories-org"
    )

    @manager = User.create!(
      organization: @organization,
      email: "manager-service-categories@example.com",
      first_name: "Service",
      last_name: "Manager",
      role: "manager",
      password: "password123",
      password_confirmation: "password123"
    )

    @category = ServiceCategory.create!(
      organization: @organization,
      code: "ENT",
      name: "Entretien",
      description: "Entretien courant des espaces verts",
      category_type: "service",
      position: 1,
      active: true
    )

    @other_category = ServiceCategory.create!(
      organization: @other_organization,
      code: "OTH",
      name: "Other Services",
      position: 1,
      active: true
    )

    @token = JwtService.encode(@manager)
  end

  test "index requires authentication" do
    get "/api/v1/service_categories"

    assert_response :unauthorized
  end

  test "index returns categories from authenticated user's organization" do
    ServiceCategory.create!(
      organization: @organization,
      code: "CRE",
      name: "Création",
      position: 2
    )

    get "/api/v1/service_categories",
        headers: {
          "Authorization" => "Bearer #{@token}"
        }

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal 2, body.length
    assert_equal @category.id, body.first["id"]
  end

  test "show returns category from same organization" do
    get "/api/v1/service_categories/#{@category.id}",
        headers: {
          "Authorization" => "Bearer #{@token}"
        }

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal @category.id, body["id"]
    assert_equal "ENT", body["code"]
    assert_equal "Entretien", body["name"]
  end

  test "show does not expose category from another organization" do
    get "/api/v1/service_categories/#{@other_category.id}",
        headers: {
          "Authorization" => "Bearer #{@token}"
        }

    assert_response :not_found
  end

  test "manager can create service category" do
    assert_difference("ServiceCategory.count", 1) do
      post "/api/v1/service_categories",
           params: {
             service_category: {
               code: "TIL",
               name: "Taille",
               description: "Taille des végétaux",
               category_type: "service",
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

    assert_equal "TIL", body["code"]
    assert_equal "Taille", body["name"]
    assert_equal @organization.id, body["organization_id"]
  end

  test "manager cannot create category for another organization" do
    assert_difference("ServiceCategory.count", 1) do
      post "/api/v1/service_categories",
           params: {
             service_category: {
               code: "HACK",
               name: "Invalid Organization Category",
               organization_id: @other_organization.id
             }
           },
           headers: {
             "Authorization" => "Bearer #{@token}"
           }
    end

    assert_response :created

    category = ServiceCategory.order(:created_at).last

    assert_equal @organization.id, category.organization_id
    assert_not_equal @other_organization.id, category.organization_id
  end

  test "manager can update service category" do
    patch "/api/v1/service_categories/#{@category.id}",
          params: {
            service_category: {
              name: "Entretien professionnel",
              position: 3
            }
          },
          headers: {
            "Authorization" => "Bearer #{@token}"
          }

    assert_response :success

    @category.reload

    assert_equal "Entretien professionnel", @category.name
    assert_equal 3, @category.position
  end

  test "manager cannot update category from another organization" do
    patch "/api/v1/service_categories/#{@other_category.id}",
          params: {
            service_category: {
              name: "Unauthorized update"
            }
          },
          headers: {
            "Authorization" => "Bearer #{@token}"
          }

    assert_response :not_found

    assert_equal "Other Services", @other_category.reload.name
  end

  test "duplicate code is rejected within organization" do
    assert_no_difference("ServiceCategory.count") do
      post "/api/v1/service_categories",
           params: {
             service_category: {
               code: "ENT",
               name: "Entretien duplicate",
               position: 5
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
