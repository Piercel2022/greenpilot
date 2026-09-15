require "test_helper"

class PlansApiTest < ActionDispatch::IntegrationTest
  test "GET /api/v1/plans returns active plans without authentication" do
    get "/api/v1/plans",
        as: :json

    assert_response :ok

    body = JSON.parse(response.body)

    assert_kind_of Array, body
    assert_equal 4, body.length
  end

  test "GET /api/v1/plans excludes inactive plans" do
    Plan.find_by!(slug: "pro").update!(active: false)

    get "/api/v1/plans",
        as: :json

    assert_response :ok

    body = JSON.parse(response.body)

    slugs = body.map { |plan| plan["slug"] }

    assert_not_includes slugs, "pro"
    assert_includes slugs, "starter"
    assert_includes slugs, "founder"
    assert_includes slugs, "business"
  end

  test "GET /api/v1/plans returns plans ordered by monthly price" do
    get "/api/v1/plans",
        as: :json

    assert_response :ok

    body = JSON.parse(response.body)

    prices = body.map { |plan| plan["monthly_price_cents"] }

    assert_equal prices.sort, prices
  end

  test "GET /api/v1/plans returns expected JSON contract" do
    get "/api/v1/plans",
        as: :json

    assert_response :ok

    body = JSON.parse(response.body)

    plan = body.first

    assert plan["id"].present?
    assert plan["name"].present?
    assert plan["slug"].present?

    assert_equal 2900, plan["monthly_price_cents"]
    assert_equal 29000, plan["yearly_price_cents"]
    assert_equal 1, plan["max_users"]
  end
end