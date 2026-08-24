require "test_helper"

class Api::V1::CustomersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organization = Organization.create!(
      name: "GreenPilot API Test",
      slug: "greenpilot-api-test"
    )

    @manager = User.create!(
      organization: @organization,
      email: "manager-api@example.com",
      first_name: "API",
      last_name: "Manager",
      role: "manager",
      password: "password123",
      password_confirmation: "password123"
    )

    @customer = Customer.create!(
      organization: @organization,
      customer_type: "individual",
      first_name: "John",
      last_name: "Customer",
      email: "john@example.com"
    )

    @token = JwtService.encode(@manager)
  end

  test "index requires authentication" do
    get "/api/v1/customers"

    assert_response :unauthorized
  end

  test "index returns customers for authenticated user" do
    get "/api/v1/customers",
        headers: {
          "Authorization" => "Bearer #{@token}"
        }

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal 1, body.length
    assert_equal @customer.id, body.first["id"]
  end

  test "show returns customer from same organization" do
    get "/api/v1/customers/#{@customer.id}",
        headers: {
          "Authorization" => "Bearer #{@token}"
        }

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal @customer.id, body["id"]
  end

  test "manager can create customer" do
    assert_difference("Customer.count", 1) do
      post "/api/v1/customers",
           params: {
             customer: {
               customer_type: "individual",
               first_name: "Alice",
               last_name: "Martin",
               email: "alice@example.com"
             }
           },
           headers: {
             "Authorization" => "Bearer #{@token}"
           }
    end

    assert_response :created

    body = JSON.parse(response.body)

    assert_equal "Alice", body["first_name"]
    assert_equal @organization.id, body["organization_id"]
  end

  test "manager can update customer" do
    patch "/api/v1/customers/#{@customer.id}",
          params: {
            customer: {
              first_name: "Updated"
            }
          },
          headers: {
            "Authorization" => "Bearer #{@token}"
          }

    assert_response :success

    assert_equal "Updated", @customer.reload.first_name
  end
end