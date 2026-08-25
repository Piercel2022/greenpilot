
require "test_helper"

class AuthApiTest < ActionDispatch::IntegrationTest
  # ============================================================
  # LOGIN
  # ============================================================

  test "user can login with valid credentials" do
    user = users(:owner_a)

    post "/api/v1/auth/login",
         params: {
           email: user.email,
           password: "password"
         },
         as: :json

    assert_response :success

    body = JSON.parse(response.body)

    assert body["token"].present?

    assert_equal user.id, body.dig("user", "id")
    assert_equal user.email, body.dig("user", "email")
    assert_equal user.organization_id, body.dig("user", "organization_id")
    assert_equal user.role, body.dig("user", "role")
  end

  test "login rejects unknown email" do
    post "/api/v1/auth/login",
         params: {
           email: "unknown@example.com",
           password: "password"
         },
         as: :json

    assert_response :unauthorized

    body = JSON.parse(response.body)

    assert_equal "Unauthorized", body["error"]
    assert_equal "Invalid email or password.", body["message"]
  end

  test "login rejects invalid password" do
    user = users(:owner_a)

    post "/api/v1/auth/login",
         params: {
           email: user.email,
           password: "wrong-password"
         },
         as: :json

    assert_response :unauthorized

    body = JSON.parse(response.body)

    assert_equal "Unauthorized", body["error"]
    assert_equal "Invalid email or password.", body["message"]
  end

  test "login requires email" do
    post "/api/v1/auth/login",
         params: {
           password: "password"
         },
         as: :json

    assert_response :unauthorized
  end

  test "login requires password" do
    user = users(:owner_a)

    post "/api/v1/auth/login",
         params: {
           email: user.email
         },
         as: :json

    assert_response :unauthorized
  end

  # ============================================================
  # CURRENT USER
  # ============================================================

  test "authenticated user can retrieve current user" do
    user = users(:owner_a)

    get "/api/v1/auth/me",
        headers: auth_headers(user)

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal user.id, body.dig("user", "id")
    assert_equal user.email, body.dig("user", "email")
    assert_equal user.first_name, body.dig("user", "first_name")
    assert_equal user.last_name, body.dig("user", "last_name")
    assert_equal user.role, body.dig("user", "role")
    assert_equal user.organization_id, body.dig("user", "organization_id")
  end

  test "current user endpoint requires authentication" do
    get "/api/v1/auth/me"

    assert_response :unauthorized

    body = JSON.parse(response.body)

    assert_equal "Unauthorized", body["error"]
  end

  test "current user endpoint rejects invalid token" do
    get "/api/v1/auth/me",
        headers: {
          "Authorization" => "Bearer invalid-token"
        }

    assert_response :unauthorized

    body = JSON.parse(response.body)

    assert_equal "Unauthorized", body["error"]
    assert_equal "Invalid or expired authentication token.", body["message"]
  end

  test "current user endpoint rejects malformed authorization header" do
    get "/api/v1/auth/me",
        headers: {
          "Authorization" => "invalid-token"
        }

    assert_response :unauthorized
  end

  private

  def auth_headers(user)
    {
      "Authorization" => "Bearer #{JwtService.encode(user)}"
    }
  end
end