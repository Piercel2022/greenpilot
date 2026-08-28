require "test_helper"

class QuoteItemsApiTest < ActionDispatch::IntegrationTest
  # ============================================================
  # AUTHENTICATION
  # ============================================================

  test "index requires authentication" do
    get "/api/v1/quote_items"

    assert_response :unauthorized
  end

  test "index rejects invalid token" do
    get "/api/v1/quote_items",
        headers: {
          "Authorization" => "Bearer invalid-token"
        }

    assert_response :unauthorized
  end

  # ============================================================
  # INDEX
  # ============================================================

  test "authenticated user can list quote items" do
    user = users(:member_a)

    get "/api/v1/quote_items",
        headers: auth_headers(user)

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal 1, body.length
    assert_equal quote_items(:quote_item_a).id, body.first["id"]
  end

  test "index only returns quote items from user's organization" do
    user = users(:member_a)

    get "/api/v1/quote_items",
        headers: auth_headers(user)

    assert_response :success

    body = JSON.parse(response.body)

    quote_item_ids = body.map { |item| item["id"] }

    assert_includes quote_item_ids, quote_items(:quote_item_a).id
    assert_not_includes quote_item_ids, quote_items(:quote_item_b).id
  end

  # ============================================================
  # SHOW
  # ============================================================

  test "user can view quote item from same organization" do
    user = users(:member_a)
    item = quote_items(:quote_item_a)

    get "/api/v1/quote_items/#{item.id}",
        headers: auth_headers(user)

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal item.id, body["id"]
    assert_equal item.description, body["description"]
    assert_equal item.quote_id, body["quote_id"]
    assert_equal item.service_item_id, body["service_item_id"]
  end

  test "user cannot access quote item from another organization" do
    user = users(:member_a)
    item = quote_items(:quote_item_b)

    get "/api/v1/quote_items/#{item.id}",
        headers: auth_headers(user)

    assert_response :not_found
  end

  test "show returns not found for unknown quote item" do
    user = users(:member_a)

    get "/api/v1/quote_items/#{SecureRandom.uuid}",
        headers: auth_headers(user)

    assert_response :not_found
  end

  # ============================================================
  # CREATE
  # ============================================================

  test "owner can create quote item" do
    user = users(:owner_a)

    assert_difference("QuoteItem.count", 1) do
      post "/api/v1/quote_items",
           params: {
             quote_item: {
               quote_id: quotes(:quote_a).id,
               service_item_id: service_items(:item_a).id,
               description: "Nouvelle prestation",
               quantity: 10,
               unit: "unit",
               unit_price: 100,
               discount_percentage: 0,
               tax_rate: 20,
               position: 1
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :created

    body = JSON.parse(response.body)

    assert_equal "Nouvelle prestation", body["description"]
    assert_equal quotes(:quote_a).id, body["quote_id"]
    assert_equal service_items(:item_a).id, body["service_item_id"]
  end

  test "admin can create quote item" do
    user = users(:admin_a)

    assert_difference("QuoteItem.count", 1) do
      post "/api/v1/quote_items",
           params: {
             quote_item: {
               quote_id: quotes(:quote_a).id,
               service_item_id: service_items(:item_a).id,
               description: "Created by admin",
               quantity: 1,
               unit: "unit",
               unit_price: 100
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :created
  end

  test "manager can create quote item" do
    user = users(:manager_a)

    assert_difference("QuoteItem.count", 1) do
      post "/api/v1/quote_items",
           params: {
             quote_item: {
               quote_id: quotes(:quote_a).id,
               service_item_id: service_items(:item_a).id,
               description: "Created by manager",
               quantity: 1,
               unit: "unit",
               unit_price: 100
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :created
  end

  test "member cannot create quote item" do
    user = users(:member_a)

    assert_no_difference("QuoteItem.count") do
      post "/api/v1/quote_items",
           params: {
             quote_item: {
               quote_id: quotes(:quote_a).id,
               service_item_id: service_items(:item_a).id,
               description: "Unauthorized item",
               quantity: 1,
               unit: "unit",
               unit_price: 100
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :forbidden
  end

  test "accountant cannot create quote item" do
    user = users(:accountant_a)

    assert_no_difference("QuoteItem.count") do
      post "/api/v1/quote_items",
           params: {
             quote_item: {
               quote_id: quotes(:quote_a).id,
               service_item_id: service_items(:item_a).id,
               description: "Unauthorized item",
               quantity: 1,
               unit: "unit",
               unit_price: 100
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :forbidden
  end

  test "field worker cannot create quote item" do
    user = users(:field_worker_a)

    assert_no_difference("QuoteItem.count") do
      post "/api/v1/quote_items",
           params: {
             quote_item: {
               quote_id: quotes(:quote_a).id,
               service_item_id: service_items(:item_a).id,
               description: "Unauthorized item",
               quantity: 1,
               unit: "unit",
               unit_price: 100
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :forbidden
  end

  # ============================================================
  # CREATE — VALIDATION
  # ============================================================

  test "create rejects quote item without description" do
    user = users(:owner_a)

    assert_no_difference("QuoteItem.count") do
      post "/api/v1/quote_items",
           params: {
             quote_item: {
               quote_id: quotes(:quote_a).id,
               service_item_id: service_items(:item_a).id,
               quantity: 1,
               unit: "unit",
               unit_price: 100
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :unprocessable_entity

    body = JSON.parse(response.body)

    assert_equal "Unprocessable Entity", body["error"]
    assert_includes body["messages"], "Description can't be blank"
  end

  test "create rejects quote item with zero quantity" do
    user = users(:owner_a)

    assert_no_difference("QuoteItem.count") do
      post "/api/v1/quote_items",
           params: {
             quote_item: {
               quote_id: quotes(:quote_a).id,
               service_item_id: service_items(:item_a).id,
               description: "Invalid quantity",
               quantity: 0,
               unit: "unit",
               unit_price: 100
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :unprocessable_entity
  end

  test "create rejects quote item with discount above one hundred" do
    user = users(:owner_a)

    assert_no_difference("QuoteItem.count") do
      post "/api/v1/quote_items",
           params: {
             quote_item: {
               quote_id: quotes(:quote_a).id,
               service_item_id: service_items(:item_a).id,
               description: "Invalid discount",
               quantity: 1,
               unit: "unit",
               unit_price: 100,
               discount_percentage: 101
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :unprocessable_entity
  end

  # ============================================================
  # CREATE — TENANT ISOLATION
  # ============================================================

  test "create rejects quote from another organization" do
    user = users(:owner_a)

    assert_no_difference("QuoteItem.count") do
      post "/api/v1/quote_items",
           params: {
             quote_item: {
               quote_id: quotes(:quote_b).id,
               service_item_id: service_items(:item_a).id,
               description: "Cross organization quote",
               quantity: 1,
               unit: "unit",
               unit_price: 100
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :forbidden
  end

  test "create rejects service item from another organization" do
    user = users(:owner_a)

    assert_no_difference("QuoteItem.count") do
      post "/api/v1/quote_items",
           params: {
             quote_item: {
               quote_id: quotes(:quote_a).id,
               service_item_id: service_items(:item_b).id,
               description: "Cross organization service item",
               quantity: 1,
               unit: "unit",
               unit_price: 100
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

  test "owner can update quote item" do
    user = users(:owner_a)
    item = quote_items(:quote_item_a)

    patch "/api/v1/quote_items/#{item.id}",
          params: {
            quote_item: {
              description: "Updated quote item",
              quantity: 20
            }
          },
          headers: auth_headers(user),
          as: :json

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal "Updated quote item", body["description"]
    assert_equal 20, body["quantity"].to_i
  end

  test "admin can update quote item" do
    user = users(:admin_a)
    item = quote_items(:quote_item_a)

    patch "/api/v1/quote_items/#{item.id}",
          params: {
            quote_item: {
              description: "Updated by admin"
            }
          },
          headers: auth_headers(user),
          as: :json

    assert_response :success
  end

  test "manager can update quote item" do
    user = users(:manager_a)
    item = quote_items(:quote_item_a)

    patch "/api/v1/quote_items/#{item.id}",
          params: {
            quote_item: {
              description: "Updated by manager"
            }
          },
          headers: auth_headers(user),
          as: :json

    assert_response :success
  end

  test "member cannot update quote item" do
    user = users(:member_a)
    item = quote_items(:quote_item_a)

    patch "/api/v1/quote_items/#{item.id}",
          params: {
            quote_item: {
              description: "Unauthorized update"
            }
          },
          headers: auth_headers(user),
          as: :json

    assert_response :forbidden
  end

  test "manager cannot update quote item from another organization" do
    user = users(:manager_a)
    item = quote_items(:quote_item_b)

    patch "/api/v1/quote_items/#{item.id}",
          params: {
            quote_item: {
              description: "Cross organization update"
            }
          },
          headers: auth_headers(user),
          as: :json

    assert_response :not_found
  end

  # ============================================================
  # UPDATE — TENANT ISOLATION
  # ============================================================

  test "manager cannot update quote item with foreign quote" do
    user = users(:manager_a)
    item = quote_items(:quote_item_a)

    patch "/api/v1/quote_items/#{item.id}",
          params: {
            quote_item: {
              quote_id: quotes(:quote_b).id
            }
          },
          headers: auth_headers(user),
          as: :json

    assert_response :unprocessable_entity

    body = JSON.parse(response.body)

    assert_includes body["messages"],
                    "Quote must belong to the same organization"
  end

  test "manager cannot update quote item with foreign service item" do
    user = users(:manager_a)
    item = quote_items(:quote_item_a)

    patch "/api/v1/quote_items/#{item.id}",
          params: {
            quote_item: {
              service_item_id: service_items(:item_b).id
            }
          },
          headers: auth_headers(user),
          as: :json

    assert_response :unprocessable_entity

    body = JSON.parse(response.body)

    assert_includes body["messages"],
                    "Service item must belong to the same organization as the quote"
  end

  # ============================================================
  # DESTROY
  # ============================================================

  test "owner can destroy quote item" do
    user = users(:owner_a)
    item = quote_items(:quote_item_a)

    assert_difference("QuoteItem.count", -1) do
      delete "/api/v1/quote_items/#{item.id}",
             headers: auth_headers(user)
    end

    assert_response :no_content
  end

  test "admin can destroy quote item" do
    user = users(:admin_a)
    item = quote_items(:quote_item_a)

    assert_difference("QuoteItem.count", -1) do
      delete "/api/v1/quote_items/#{item.id}",
             headers: auth_headers(user)
    end

    assert_response :no_content
  end

  test "manager cannot destroy quote item" do
    user = users(:manager_a)
    item = quote_items(:quote_item_a)

    assert_no_difference("QuoteItem.count") do
      delete "/api/v1/quote_items/#{item.id}",
             headers: auth_headers(user)
    end

    assert_response :forbidden
  end

  test "member cannot destroy quote item" do
    user = users(:member_a)
    item = quote_items(:quote_item_a)

    assert_no_difference("QuoteItem.count") do
      delete "/api/v1/quote_items/#{item.id}",
             headers: auth_headers(user)
    end

    assert_response :forbidden
  end

  test "owner cannot destroy quote item from another organization" do
    user = users(:owner_a)
    item = quote_items(:quote_item_b)

    assert_no_difference("QuoteItem.count") do
      delete "/api/v1/quote_items/#{item.id}",
             headers: auth_headers(user)
    end

    assert_response :not_found
  end
end
