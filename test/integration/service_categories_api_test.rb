require "test_helper"

class ServiceCategoriesApiTest < ActionDispatch::IntegrationTest
  # ============================================================
  # AUTHENTICATION
  # ============================================================

  test "index requires authentication" do
    get "/api/v1/service_categories"

    assert_response :unauthorized
  end

  test "index rejects invalid token" do
    get "/api/v1/service_categories",
        headers: {
          "Authorization" => "Bearer invalid-token"
        }

    assert_response :unauthorized
  end

  # ============================================================
  # INDEX
  # ============================================================

  test "authenticated user can list service categories" do
    user = users(:owner_a)

    get "/api/v1/service_categories",
        headers: auth_headers(user)

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal 1, body.length
    assert_equal service_categories(:category_a).id, body.first["id"]
  end

  test "index only returns categories from user's organization" do
    user = users(:owner_a)

    get "/api/v1/service_categories",
        headers: auth_headers(user)

    assert_response :success

    body = JSON.parse(response.body)

    category_ids = body.map { |category| category["id"] }

    assert_includes category_ids, service_categories(:category_a).id
    assert_not_includes category_ids, service_categories(:category_b).id
  end

  test "index orders categories by position then name" do
    user = users(:owner_a)
    organization = organizations(:organization_a)

    second_category = ServiceCategory.create!(
      organization: organization,
      code: "TAIL",
      name: "Taille",
      category_type: "maintenance",
      position: 2,
      active: true
    )

    first_category = ServiceCategory.create!(
      organization: organization,
      code: "ARB",
      name: "Arboriculture",
      category_type: "maintenance",
      position: 1,
      active: true
    )

    get "/api/v1/service_categories",
        headers: auth_headers(user)

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal [
      first_category.id,
      service_categories(:category_a).id,
      second_category.id
    ], body.map { |category| category["id"] }
  end

  # ============================================================
  # SHOW
  # ============================================================

  test "user can view category from same organization" do
    user = users(:owner_a)
    category = service_categories(:category_a)

    get "/api/v1/service_categories/#{category.id}",
        headers: auth_headers(user)

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal category.id, body["id"]
    assert_equal category.code, body["code"]
    assert_equal category.name, body["name"]
  end

  test "user cannot access category from another organization" do
    user = users(:owner_a)
    category = service_categories(:category_b)

    get "/api/v1/service_categories/#{category.id}",
        headers: auth_headers(user)

    assert_response :not_found
  end

  test "show returns not found for unknown category" do
    user = users(:owner_a)

    get "/api/v1/service_categories/#{SecureRandom.uuid}",
        headers: auth_headers(user)

    assert_response :not_found
  end

  # ============================================================
  # CREATE
  # ============================================================

  test "owner can create service category" do
    user = users(:owner_a)

    assert_difference("ServiceCategory.count", 1) do
      post "/api/v1/service_categories",
           params: {
             service_category: {
               code: "ELAG",
               name: "Élagage",
               description: "Travaux d'élagage",
               category_type: "maintenance",
               position: 3,
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
    assert_equal user.organization_id, body["organization_id"]
  end

  test "manager can create service category" do
    user = users(:manager_a)

    assert_difference("ServiceCategory.count", 1) do
      post "/api/v1/service_categories",
           params: {
             service_category: {
               code: "ELAG",
               name: "Élagage",
               category_type: "maintenance",
               position: 3,
               active: true
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :created
  end

  test "member cannot create service category" do
    user = users(:member_a)

    assert_no_difference("ServiceCategory.count") do
      post "/api/v1/service_categories",
           params: {
             service_category: {
               code: "ELAG",
               name: "Élagage"
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :forbidden
  end

  test "create rejects duplicate code within same organization" do
    user = users(:owner_a)
    existing_category = service_categories(:category_a)

    assert_no_difference("ServiceCategory.count") do
      post "/api/v1/service_categories",
           params: {
             service_category: {
               code: existing_category.code,
               name: "Autre entretien"
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

    assert_difference("ServiceCategory.count", 1) do
      post "/api/v1/service_categories",
           params: {
             service_category: {
               code: service_categories(:category_b).code,
               name: "Création locale",
               category_type: "creation"
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :created

    body = JSON.parse(response.body)

    assert_equal service_categories(:category_b).code, body["code"]
    assert_equal user.organization_id, body["organization_id"]
  end

  test "create rejects category without code" do
    user = users(:owner_a)

    assert_no_difference("ServiceCategory.count") do
      post "/api/v1/service_categories",
           params: {
             service_category: {
               name: "Sans code"
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

  test "create rejects category without name" do
    user = users(:owner_a)

    assert_no_difference("ServiceCategory.count") do
      post "/api/v1/service_categories",
           params: {
             service_category: {
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

  test "owner can update service category" do
    user = users(:owner_a)
    category = service_categories(:category_a)

    patch "/api/v1/service_categories/#{category.id}",
          params: {
            service_category: {
              name: "Entretien courant",
              description: "Description mise à jour"
            }
          },
          headers: auth_headers(user),
          as: :json

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal "Entretien courant", body["name"]
    assert_equal "Description mise à jour", body["description"]
  end

  test "manager can update service category" do
    user = users(:manager_a)
    category = service_categories(:category_a)

    patch "/api/v1/service_categories/#{category.id}",
          params: {
            service_category: {
              name: "Entretien professionnel"
            }
          },
          headers: auth_headers(user),
          as: :json

    assert_response :success
  end

  test "member cannot update service category" do
    user = users(:member_a)
    category = service_categories(:category_a)

    original_name = category.name

    patch "/api/v1/service_categories/#{category.id}",
          params: {
            service_category: {
              name: "Unauthorized update"
            }
          },
          headers: auth_headers(user),
          as: :json

    assert_response :forbidden

    assert_equal original_name, category.reload.name
  end

  test "user cannot update category from another organization" do
    user = users(:owner_a)
    category = service_categories(:category_b)

    patch "/api/v1/service_categories/#{category.id}",
          params: {
            service_category: {
              name: "Unauthorized cross organization update"
            }
          },
          headers: auth_headers(user),
          as: :json

    assert_response :not_found
  end

  test "update rejects duplicate code within same organization" do
    user = users(:owner_a)
    category = service_categories(:category_a)

    another_category = ServiceCategory.create!(
      organization: organizations(:organization_a),
      code: "TAIL",
      name: "Taille",
      category_type: "maintenance"
    )

    original_code = another_category.code

    patch "/api/v1/service_categories/#{another_category.id}",
          params: {
            service_category: {
              code: category.code
            }
          },
          headers: auth_headers(user),
          as: :json

    assert_response :unprocessable_entity

    body = JSON.parse(response.body)

    assert_equal "Unprocessable Entity", body["error"]
    assert_includes body["messages"], "Code has already been taken"

    assert_equal original_code, another_category.reload.code
  end

  # ============================================================
  # DELETE
  # ============================================================

  test "owner can destroy service category" do
    user = users(:owner_a)

    category = ServiceCategory.create!(
      organization: user.organization,
      code: "DELETE",
      name: "Category to delete"
    )

    assert_difference("ServiceCategory.count", -1) do
      delete "/api/v1/service_categories/#{category.id}",
             headers: auth_headers(user)
    end

    assert_response :no_content
  end

  test "admin can destroy service category" do
    user = users(:admin_a)

    category = ServiceCategory.create!(
      organization: user.organization,
      code: "DELETE",
      name: "Category to delete"
    )

    assert_difference("ServiceCategory.count", -1) do
      delete "/api/v1/service_categories/#{category.id}",
             headers: auth_headers(user)
    end

    assert_response :no_content
  end

  test "manager cannot destroy service category" do
    user = users(:manager_a)
    category = service_categories(:category_a)

    assert_no_difference("ServiceCategory.count") do
      delete "/api/v1/service_categories/#{category.id}",
             headers: auth_headers(user)
    end

    assert_response :forbidden
  end

  test "member cannot destroy service category" do
    user = users(:member_a)
    category = service_categories(:category_a)

    assert_no_difference("ServiceCategory.count") do
      delete "/api/v1/service_categories/#{category.id}",
             headers: auth_headers(user)
    end

    assert_response :forbidden
  end

  test "user cannot destroy category from another organization" do
    user = users(:owner_a)
    category = service_categories(:category_b)

    assert_no_difference("ServiceCategory.count") do
      delete "/api/v1/service_categories/#{category.id}",
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