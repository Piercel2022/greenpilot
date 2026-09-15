require "test_helper"

class AdminDashboardApiTest < ActionDispatch::IntegrationTest
  # ============================================================
  # AUTHENTICATION
  # ============================================================

  test "dashboard requires authentication" do
    get "/api/v1/admin/dashboard"

    assert_response :unauthorized
  end

  test "dashboard rejects invalid token" do
    get "/api/v1/admin/dashboard",
        headers: {
          "Authorization" => "Bearer invalid-token"
        }

    assert_response :unauthorized
  end

  # ============================================================
  # AUTHORIZATION
  # ============================================================

  test "organization admin cannot access platform dashboard" do
    user = users(:admin_a)

    get "/api/v1/admin/dashboard",
        headers: auth_headers(user)

    assert_response :forbidden
  end

  test "platform admin can access dashboard" do
    user = users(:platform_admin_a)

    get "/api/v1/admin/dashboard",
        headers: auth_headers(user)

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal Organization.count, body["organizations_count"]
    assert_equal User.count, body["users_count"]
    assert_equal Subscription.active.count,
                 body["active_subscriptions_count"]
    assert_equal Subscription.trialing.count,
                 body["trialing_subscriptions_count"]

    assert body.key?("mrr_cents")
    assert body.key?("plans")
    assert body.key?("recent_organizations")
  end

  test "owner cannot access dashboard" do
    user = users(:owner_a)

    get "/api/v1/admin/dashboard",
        headers: auth_headers(user)

    assert_response :forbidden
  end

  test "manager cannot access dashboard" do
    user = users(:manager_a)

    get "/api/v1/admin/dashboard",
        headers: auth_headers(user)

    assert_response :forbidden
  end

  test "accountant cannot access dashboard" do
    user = users(:accountant_a)

    get "/api/v1/admin/dashboard",
        headers: auth_headers(user)

    assert_response :forbidden
  end

  test "field worker cannot access dashboard" do
    user = users(:field_worker_a)

    get "/api/v1/admin/dashboard",
        headers: auth_headers(user)

    assert_response :forbidden
  end

  test "member cannot access dashboard" do
    user = users(:member_a)

    get "/api/v1/admin/dashboard",
        headers: auth_headers(user)

    assert_response :forbidden
  end

  # ============================================================
  # JSON CONTRACT
  # ============================================================

  test "dashboard returns plan statistics" do
    user = users(:platform_admin_a)

    get "/api/v1/admin/dashboard",
        headers: auth_headers(user)

    assert_response :success

    body = JSON.parse(response.body)

    assert_kind_of Array, body["plans"]

    starter = body["plans"].find { |plan| plan["slug"] == "starter" }

    assert_not_nil starter
    assert_equal "Starter", starter["name"]
    assert starter.key?("subscriptions_count")
  end

  test "dashboard returns recent organizations" do
    user = users(:platform_admin_a)

    get "/api/v1/admin/dashboard",
        headers: auth_headers(user)

    assert_response :success

    body = JSON.parse(response.body)

    assert_kind_of Array, body["recent_organizations"]
    assert body["recent_organizations"].length <= 10

    organization = body["recent_organizations"].first

    if organization
      assert organization["id"].present?
      assert organization["name"].present?
      assert organization.key?("created_at")
      assert organization.key?("subscription")
    end
  end
end