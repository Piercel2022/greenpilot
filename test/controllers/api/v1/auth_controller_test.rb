require "test_helper"

class Api::V1::AuthControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organization = Organization.create!(
      name: "Auth Test Organization",
      slug: "auth-test-organization"
    )

    @user = User.create!(
      organization: @organization,
      email: "auth@example.com",
      first_name: "Auth",
      last_name: "User",
      phone: "0600000000",
      role: "manager",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  test "login returns JWT for valid credentials" do
    post "/api/v1/auth/login",
         params: {
           email: @user.email,
           password: "password123"
         }

    assert_response :success

    body = JSON.parse(response.body)

    assert body["token"].present?
    assert_equal @user.id, body["user"]["id"]
    assert_equal @user.email, body["user"]["email"]
    assert_equal "manager", body["user"]["role"]
  end

  test "login rejects invalid password" do
    post "/api/v1/auth/login",
         params: {
           email: @user.email,
           password: "wrong-password"
         }

    assert_response :unauthorized

    body = JSON.parse(response.body)

    assert_equal "Unauthorized", body["error"]
  end

  test "login rejects unknown email" do
    post "/api/v1/auth/login",
         params: {
           email: "unknown@example.com",
           password: "password123"
         }

    assert_response :unauthorized
  end

  test "login rejects inactive user" do
    @user.update!(active: false)

    post "/api/v1/auth/login",
         params: {
           email: @user.email,
           password: "password123"
         }

    assert_response :unauthorized
  end

  test "me returns authenticated user" do
    token = JwtService.encode(@user)

    get "/api/v1/auth/me",
        headers: {
          "Authorization" => "Bearer #{token}"
        }

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal @user.id, body["user"]["id"]
    assert_equal @user.email, body["user"]["email"]
    assert_equal @user.organization_id, body["user"]["organization_id"]
  end

  test "me rejects request without token" do
    get "/api/v1/auth/me"

    assert_response :unauthorized

    body = JSON.parse(response.body)

    assert_equal "Unauthorized", body["error"]
  end

  test "me rejects invalid token" do
    get "/api/v1/auth/me",
        headers: {
          "Authorization" => "Bearer invalid-token"
        }

    assert_response :unauthorized
  end
end