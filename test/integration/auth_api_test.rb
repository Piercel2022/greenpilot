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
  # REGISTRATION
  # ============================================================

  test "registration creates organization with starter subscription" do
    assert_difference("Organization.count", 1) do
      assert_difference("User.count", 1) do
        assert_difference("Subscription.count", 1) do
          post "/api/v1/auth/register",
               params: {
                 first_name: "New",
                 last_name: "Owner",
                 organization_name: "New GreenPilot Company",
                 email: "new-owner@example.com",
                 password: "password123",
                 password_confirmation: "password123"
               },
               as: :json
        end
      end
    end

    assert_response :created

    body = JSON.parse(response.body)

    assert body["token"].present?
    assert body.dig("user", "id").present?

    user = User.find(body.dig("user", "id"))
    organization = user.organization
    subscription = organization.subscription

    assert_equal "owner", user.role

    assert_not_nil subscription
    assert_equal "starter", subscription.plan.slug
    assert_equal "trialing", subscription.status
    assert_equal "monthly", subscription.billing_interval

    assert_in_delta 14.days.from_now.to_f,
                     subscription.trial_ends_at.to_f,
                     5.seconds
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
end