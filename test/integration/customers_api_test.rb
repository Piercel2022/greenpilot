require "test_helper"

class CustomersApiTest < ActionDispatch::IntegrationTest
  # ============================================================
  # AUTHENTICATION
  # ============================================================

  test "index requires authentication" do
    get "/api/v1/customers"

    assert_response :unauthorized
  end

  test "index rejects invalid token" do
    get "/api/v1/customers",
        headers: {
          "Authorization" => "Bearer invalid-token"
        }

    assert_response :unauthorized
  end

  # ============================================================
  # INDEX
  # ============================================================

  test "authenticated user can list customers" do
    user = users(:owner_a)

    get "/api/v1/customers",
        headers: auth_headers(user)

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal 1, body.length
    assert_equal customers(:customer_a).id, body.first["id"]
  end

  test "index only returns customers from user's organization" do
    user = users(:owner_a)

    get "/api/v1/customers",
        headers: auth_headers(user)

    assert_response :success

    body = JSON.parse(response.body)

    customer_ids = body.map { |customer| customer["id"] }

    assert_includes customer_ids, customers(:customer_a).id
    assert_not_includes customer_ids, customers(:customer_b).id
  end

  # ============================================================
  # SHOW
  # ============================================================

  test "user can view customer from same organization" do
    user = users(:owner_a)
    customer = customers(:customer_a)

    get "/api/v1/customers/#{customer.id}",
        headers: auth_headers(user)

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal customer.id, body["id"]
  end

  test "user cannot access customer from another organization" do
    user = users(:owner_a)
    customer = customers(:customer_b)

    get "/api/v1/customers/#{customer.id}",
        headers: auth_headers(user)

    assert_response :not_found
  end

  test "show returns not found for unknown customer" do
    user = users(:owner_a)

    get "/api/v1/customers/#{SecureRandom.uuid}",
        headers: auth_headers(user)

    assert_response :not_found
  end

  # ============================================================
  # CREATE
  # ============================================================

  test "owner can create customer" do
    user = users(:owner_a)

    assert_difference("Customer.count", 1) do
      post "/api/v1/customers",
           params: {
             customer: {
               customer_type: "individual",
               first_name: "Jean",
               last_name: "Dupont",
               email: "jean.dupont@example.fr",
               phone: "0600000099",
               active: true
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :created

    body = JSON.parse(response.body)

    assert_equal "Jean", body["first_name"]
    assert_equal "Dupont", body["last_name"]
    assert_equal user.organization_id, body["organization_id"]
  end

  test "member cannot create customer" do
    user = users(:member_a)

    assert_no_difference("Customer.count") do
      post "/api/v1/customers",
           params: {
             customer: {
               customer_type: "individual",
               first_name: "Unauthorized",
               last_name: "User"
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

  test "owner can update customer" do
    user = users(:owner_a)
    customer = customers(:customer_a)

    patch "/api/v1/customers/#{customer.id}",
          params: {
            customer: {
              phone: "0600000011",
              notes: "Updated through API."
            }
          },
          headers: auth_headers(user),
          as: :json

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal "0600000011", body["phone"]
    assert_equal "Updated through API.", body["notes"]
  end

  test "member cannot update customer" do
    user = users(:member_a)
    customer = customers(:customer_a)

    original_phone = customer.phone

    patch "/api/v1/customers/#{customer.id}",
          params: {
            customer: {
              phone: "0600000099"
            }
          },
          headers: auth_headers(user),
          as: :json

    assert_response :forbidden

    assert_equal original_phone, customer.reload.phone
  end

  test "user cannot update customer from another organization" do
    user = users(:owner_a)
    customer = customers(:customer_b)

    patch "/api/v1/customers/#{customer.id}",
          params: {
            customer: {
              notes: "Unauthorized update."
            }
          },
          headers: auth_headers(user),
          as: :json

    assert_response :not_found
  end

  # ============================================================
  # DELETE
  # ============================================================

  test "owner can destroy customer" do
    user = users(:owner_a)

    customer = Customer.create!(
      organization: user.organization,
      customer_type: :individual,
      first_name: "Delete",
      last_name: "Test"
    )

    assert_difference("Customer.count", -1) do
      delete "/api/v1/customers/#{customer.id}",
             headers: auth_headers(user)
    end

    assert_response :no_content
  end

  test "member cannot destroy customer" do
    user = users(:member_a)
    customer = customers(:customer_a)

    assert_no_difference("Customer.count") do
      delete "/api/v1/customers/#{customer.id}",
             headers: auth_headers(user)
    end

    assert_response :forbidden
  end

  test "user cannot destroy customer from another organization" do
    user = users(:owner_a)
    customer = customers(:customer_b)

    assert_no_difference("Customer.count") do
      delete "/api/v1/customers/#{customer.id}",
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