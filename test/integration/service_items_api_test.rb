require "test_helper"

class ServiceItemsApiTest < ActionDispatch::IntegrationTest
  # ============================================================
  # AUTHENTICATION
  # ============================================================

  test "index requires authentication" do
    get "/api/v1/service_items"

    assert_response :unauthorized
  end

  test "index rejects invalid token" do
    get "/api/v1/service_items",
        headers: {
          "Authorization" => "Bearer invalid-token"
        }

    assert_response :unauthorized
  end

  # ============================================================
  # INDEX
  # ============================================================

  test "authenticated user can list service items" do
    user = users(:owner_a)

    get "/api/v1/service_items",
        headers: auth_headers(user)

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal 1, body.length
    assert_equal service_items(:item_a).id, body.first["id"]
  end

  test "index only returns items from user's organization" do
    user = users(:owner_a)

    get "/api/v1/service_items",
        headers: auth_headers(user)

    assert_response :success

    body = JSON.parse(response.body)

    item_ids = body.map { |item| item["id"] }

    assert_includes item_ids, service_items(:item_a).id
    assert_not_includes item_ids, service_items(:item_b).id
  end


  test "index orders items by position then name" do
    user = users(:owner_a)
    organization = organizations(:organization_a)
    category = service_categories(:category_a)

    second_item = ServiceItem.create!(
      organization: organization,
      service_category: category,
      code: "TAIL",
      name: "Taille",
      position: 2,
      active: true
    )

    first_item = ServiceItem.create!(
      organization: organization,
      service_category: category,
      code: "ARB",
      name: "Arboriculture",
      position: 1,
      active: true
    )

    get "/api/v1/service_items",
        headers: auth_headers(user)

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal [
      first_item.id,
      service_items(:item_a).id,
      second_item.id
    ], body.map { |item| item["id"] }
  end

  # ============================================================
  # SHOW
  # ============================================================

  test "user can view item from same organization" do
    user = users(:owner_a)
    item = service_items(:item_a)

    get "/api/v1/service_items/#{item.id}",
        headers: auth_headers(user)

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal item.id, body["id"]
    assert_equal item.code, body["code"]
    assert_equal item.name, body["name"]
  end

  test "user cannot access item from another organization" do
    user = users(:owner_a)
    item = service_items(:item_b)

    get "/api/v1/service_items/#{item.id}",
        headers: auth_headers(user)

    assert_response :not_found
  end

  test "show returns not found for unknown item" do
    user = users(:owner_a)

    get "/api/v1/service_items/#{SecureRandom.uuid}",
        headers: auth_headers(user)

    assert_response :not_found
  end

  # ============================================================
  # CREATE
  # ============================================================

  test "owner can create service item" do
    user = users(:owner_a)
    category = service_categories(:category_a)

    assert_difference("ServiceItem.count", 1) do
      post "/api/v1/service_items",
           params: {
             service_item: {
               service_category_id: category.id,
               code: "ELAG",
               name: "Élagage",
               description: "Travaux d'élagage",
               default_quantity: 1,
               default_unit_price: 150.00,
               default_margin_percentage: 30.00,
               labor_cost: 80.00,
               material_cost: 10.00,
               equipment_cost: 15.00,
               overhead_cost: 10.00,
               estimated_duration_minutes: 120,
               unit: "hour",
               position: 2,
               active: true
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :created

    body = JSON.parse(response.body)

    assert_equal "ELAG", body["code"]
    assert_equal "Élagage", body["name"]
    assert_equal category.id, body["service_category_id"]
    assert_equal user.organization_id, body["organization_id"]
  end

  test "manager can create service item" do
    user = users(:manager_a)
    category = service_categories(:category_a)

    assert_difference("ServiceItem.count", 1) do
      post "/api/v1/service_items",
           params: {
             service_item: {
               service_category_id: category.id,
               code: "ELAG",
               name: "Élagage"
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :created
  end

  test "member cannot create service item" do
    user = users(:member_a)
    category = service_categories(:category_a)

    assert_no_difference("ServiceItem.count") do
      post "/api/v1/service_items",
           params: {
             service_item: {
               service_category_id: category.id,
               code: "ELAG",
               name: "Élagage"
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :forbidden
  end

  test "user cannot create item for category from another organization" do
    user = users(:owner_a)
    category = service_categories(:category_b)

    assert_no_difference("ServiceItem.count") do
      post "/api/v1/service_items",
           params: {
             service_item: {
               service_category_id: category.id,
               code: "CROSS",
               name: "Cross organization item"
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :forbidden
  end

  test "create rejects duplicate code within same organization" do
    user = users(:owner_a)
    category = service_categories(:category_a)
    existing_item = service_items(:item_a)

    assert_no_difference("ServiceItem.count") do
      post "/api/v1/service_items",
           params: {
             service_item: {
               service_category_id: category.id,
               code: existing_item.code,
               name: "Another mowing service"
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
    category = service_categories(:category_a)

    assert_difference("ServiceItem.count", 1) do
      post "/api/v1/service_items",
           params: {
             service_item: {
               service_category_id: category.id,
               code: service_items(:item_b).code,
               name: "Local creation service"
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :created

    body = JSON.parse(response.body)

    assert_equal service_items(:item_b).code, body["code"]
    assert_equal user.organization_id, body["organization_id"]
  end

  test "create rejects item without code" do
    user = users(:owner_a)
    category = service_categories(:category_a)

    assert_no_difference("ServiceItem.count") do
      post "/api/v1/service_items",
           params: {
             service_item: {
               service_category_id: category.id,
               name: "Without code"
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :unprocessable_entity

    body = JSON.parse(response.body)

    assert_equal "Unprocessable Entity", body["error"]
    assert_includes body["messages"], "Code can't be blank"
  end

  test "create rejects item without name" do
    user = users(:owner_a)
    category = service_categories(:category_a)

    assert_no_difference("ServiceItem.count") do
      post "/api/v1/service_items",
           params: {
             service_item: {
               service_category_id: category.id,
               code: "NONAME"
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :unprocessable_entity

    body = JSON.parse(response.body)

    assert_equal "Unprocessable Entity", body["error"]
    assert_includes body["messages"], "Name can't be blank"
  end

  # ============================================================
  # UPDATE
  # ============================================================

  test "owner can update service item" do
    user = users(:owner_a)
    item = service_items(:item_a)

    patch "/api/v1/service_items/#{item.id}",
          params: {
            service_item: {
              name: "Tonte professionnelle",
              default_unit_price: 0.95
            }
          },
          headers: auth_headers(user),
          as: :json

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal "Tonte professionnelle", body["name"]
    assert_equal "0.95", body["default_unit_price"]
  end

  test "manager can update service item" do
    user = users(:manager_a)
    item = service_items(:item_a)

    patch "/api/v1/service_items/#{item.id}",
          params: {
            service_item: {
              name: "Tonte manager"
            }
          },
          headers: auth_headers(user),
          as: :json

    assert_response :success
  end

  test "member cannot update service item" do
    user = users(:member_a)
    item = service_items(:item_a)

    original_name = item.name

    patch "/api/v1/service_items/#{item.id}",
          params: {
            service_item: {
              name: "Unauthorized update"
            }
          },
          headers: auth_headers(user),
          as: :json

    assert_response :forbidden

    assert_equal original_name, item.reload.name
  end

  test "user cannot update item from another organization" do
    user = users(:owner_a)
    item = service_items(:item_b)

    patch "/api/v1/service_items/#{item.id}",
          params: {
            service_item: {
              name: "Unauthorized cross organization update"
            }
          },
          headers: auth_headers(user),
          as: :json

    assert_response :not_found
  end

  test "user cannot move item to category from another organization" do
    user = users(:owner_a)
    item = service_items(:item_a)
    category = service_categories(:category_b)

    original_category_id = item.service_category_id

    patch "/api/v1/service_items/#{item.id}",
        params: {
          service_item: {
            service_category_id: category.id
          }
        },
        headers: auth_headers(user),
        as: :json

    assert_response :unprocessable_entity

    body = JSON.parse(response.body)

    assert_equal "Unprocessable Entity", body["error"]
    assert_includes body["messages"],
                  "Service category must belong to the same organization"

    assert_equal original_category_id, item.reload.service_category_id
  end

  test "update rejects duplicate code within same organization" do
    user = users(:owner_a)
    category = service_categories(:category_a)

    another_item = ServiceItem.create!(
      organization: organizations(:organization_a),
      service_category: category,
      code: "TAIL",
      name: "Taille"
    )

    patch "/api/v1/service_items/#{another_item.id}",
          params: {
            service_item: {
              code: service_items(:item_a).code
            }
          },
          headers: auth_headers(user),
          as: :json

    assert_response :unprocessable_entity

    body = JSON.parse(response.body)

    assert_equal "Unprocessable Entity", body["error"]
    assert_includes body["messages"], "Code has already been taken"

    assert_equal "TAIL", another_item.reload.code
  end

  # ============================================================
  # DELETE
  # ============================================================

  test "owner can destroy service item" do
    user = users(:owner_a)

    item = ServiceItem.create!(
      organization: user.organization,
      service_category: service_categories(:category_a),
      code: "DELETE",
      name: "Item to delete"
    )

    assert_difference("ServiceItem.count", -1) do
      delete "/api/v1/service_items/#{item.id}",
             headers: auth_headers(user)
    end

    assert_response :no_content
  end

  test "admin can destroy service item" do
    user = users(:admin_a)

    item = ServiceItem.create!(
      organization: user.organization,
      service_category: service_categories(:category_a),
      code: "DELETE",
      name: "Item to delete"
    )

    assert_difference("ServiceItem.count", -1) do
      delete "/api/v1/service_items/#{item.id}",
             headers: auth_headers(user)
    end

    assert_response :no_content
  end

  test "manager cannot destroy service item" do
    user = users(:manager_a)
    item = service_items(:item_a)

    assert_no_difference("ServiceItem.count") do
      delete "/api/v1/service_items/#{item.id}",
             headers: auth_headers(user)
    end

    assert_response :forbidden
  end

  test "member cannot destroy service item" do
    user = users(:member_a)
    item = service_items(:item_a)

    assert_no_difference("ServiceItem.count") do
      delete "/api/v1/service_items/#{item.id}",
             headers: auth_headers(user)
    end

    assert_response :forbidden
  end

  test "user cannot destroy item from another organization" do
    user = users(:owner_a)
    item = service_items(:item_b)

    assert_no_difference("ServiceItem.count") do
      delete "/api/v1/service_items/#{item.id}",
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
