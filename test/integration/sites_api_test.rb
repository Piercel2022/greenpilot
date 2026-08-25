require "test_helper"

class SitesApiTest < ActionDispatch::IntegrationTest
  # ============================================================
  # AUTHENTICATION
  # ============================================================

  test "index requires authentication" do
    get "/api/v1/sites"

    assert_response :unauthorized
  end

  test "index rejects invalid token" do
    get "/api/v1/sites",
        headers: {
          "Authorization" => "Bearer invalid-token"
        }

    assert_response :unauthorized
  end

  # ============================================================
  # INDEX
  # ============================================================

  test "authenticated user can list sites" do
    user = users(:owner_a)

    get "/api/v1/sites",
        headers: auth_headers(user)

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal 1, body.length
    assert_equal sites(:site_a).id, body.first["id"]
  end

  test "index only returns sites from user's organization" do
    user = users(:owner_a)

    get "/api/v1/sites",
        headers: auth_headers(user)

    assert_response :success

    body = JSON.parse(response.body)

    site_ids = body.map { |site| site["id"] }

    assert_includes site_ids, sites(:site_a).id
    assert_not_includes site_ids, sites(:site_b).id
  end

  # ============================================================
  # SHOW
  # ============================================================

  test "user can view site from same organization" do
    user = users(:owner_a)
    site = sites(:site_a)

    get "/api/v1/sites/#{site.id}",
        headers: auth_headers(user)

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal site.id, body["id"]
    assert_equal site.name, body["name"]
  end

  test "user cannot access site from another organization" do
    user = users(:owner_a)
    site = sites(:site_b)

    get "/api/v1/sites/#{site.id}",
        headers: auth_headers(user)

    assert_response :not_found
  end

  test "show returns not found for unknown site" do
    user = users(:owner_a)

    get "/api/v1/sites/#{SecureRandom.uuid}",
        headers: auth_headers(user)

    assert_response :not_found
  end

  # ============================================================
  # CREATE
  # ============================================================

  test "owner can create site" do
    user = users(:owner_a)
    customer = customers(:customer_a)

    assert_difference("Site.count", 1) do
      post "/api/v1/sites",
           params: {
             site: {
               customer_id: customer.id,
               name: "Nouveau jardin",
               site_type: "garden",
               address_line1: "10 rue des Jardins",
               postal_code: "67000",
               city: "Strasbourg",
               country: "France",
               active: true
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :created

    body = JSON.parse(response.body)

    assert_equal "Nouveau jardin", body["name"]
    assert_equal customer.id, body["customer_id"]
    assert_equal user.organization_id, body["organization_id"]
  end

  test "member cannot create site" do
    user = users(:member_a)
    customer = customers(:customer_a)

    assert_no_difference("Site.count") do
      post "/api/v1/sites",
           params: {
             site: {
               customer_id: customer.id,
               name: "Unauthorized site"
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :forbidden
  end

  test "user cannot create site for customer from another organization" do
    user = users(:owner_a)
    customer = customers(:customer_b)

    assert_no_difference("Site.count") do
      post "/api/v1/sites",
           params: {
             site: {
               customer_id: customer.id,
               name: "Cross organization site"
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :forbidden
  end

  test "create rejects site without name" do
    user = users(:owner_a)
    customer = customers(:customer_a)

    assert_no_difference("Site.count") do
      post "/api/v1/sites",
           params: {
             site: {
               customer_id: customer.id
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

  test "owner can update site" do
    user = users(:owner_a)
    site = sites(:site_a)

    patch "/api/v1/sites/#{site.id}",
          params: {
            site: {
              name: "Jardin principal rénové",
              city: "Strasbourg"
            }
          },
          headers: auth_headers(user),
          as: :json

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal "Jardin principal rénové", body["name"]
    assert_equal "Strasbourg", body["city"]
  end

  test "member cannot update site" do
    user = users(:member_a)
    site = sites(:site_a)

    original_name = site.name

    patch "/api/v1/sites/#{site.id}",
          params: {
            site: {
              name: "Unauthorized update"
            }
          },
          headers: auth_headers(user),
          as: :json

    assert_response :forbidden

    assert_equal original_name, site.reload.name
  end

  test "user cannot update site from another organization" do
    user = users(:owner_a)
    site = sites(:site_b)

    patch "/api/v1/sites/#{site.id}",
          params: {
            site: {
              name: "Unauthorized cross organization update"
            }
          },
          headers: auth_headers(user),
          as: :json

    assert_response :not_found
  end

  test "user cannot move site to customer from another organization" do
    user = users(:owner_a)
    site = sites(:site_a)
    customer = customers(:customer_b)

    original_customer_id = site.customer_id

    patch "/api/v1/sites/#{site.id}",
          params: {
            site: {
              customer_id: customer.id
            }
          },
          headers: auth_headers(user),
          as: :json

    assert_response :unprocessable_entity

    assert_equal original_customer_id, site.reload.customer_id
  end

  # ============================================================
  # DELETE
  # ============================================================

  test "owner can destroy site" do
    user = users(:owner_a)

    site = Site.create!(
      organization: user.organization,
      customer: customers(:customer_a),
      name: "Site to delete"
    )

    assert_difference("Site.count", -1) do
      delete "/api/v1/sites/#{site.id}",
             headers: auth_headers(user)
    end

    assert_response :no_content
  end

  test "member cannot destroy site" do
    user = users(:member_a)
    site = sites(:site_a)

    assert_no_difference("Site.count") do
      delete "/api/v1/sites/#{site.id}",
             headers: auth_headers(user)
    end

    assert_response :forbidden
  end

  test "user cannot destroy site from another organization" do
    user = users(:owner_a)
    site = sites(:site_b)

    assert_no_difference("Site.count") do
      delete "/api/v1/sites/#{site.id}",
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