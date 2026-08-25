require "test_helper"

class QuotesApiTest < ActionDispatch::IntegrationTest
  # ============================================================
  # AUTHENTICATION
  # ============================================================

  test "index requires authentication" do
    get "/api/v1/quotes"

    assert_response :unauthorized
  end

  test "index rejects invalid token" do
    get "/api/v1/quotes",
        headers: {
          "Authorization" => "Bearer invalid-token"
        }

    assert_response :unauthorized
  end

  # ============================================================
  # INDEX
  # ============================================================

  test "authenticated user can list quotes" do
    user = users(:owner_a)

    get "/api/v1/quotes",
        headers: auth_headers(user)

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal 1, body.length
    assert_equal quotes(:quote_a).id, body.first["id"]
  end

  test "index only returns quotes from user's organization" do
    user = users(:owner_a)

    get "/api/v1/quotes",
        headers: auth_headers(user)

    assert_response :success

    body = JSON.parse(response.body)

    quote_ids = body.map { |quote| quote["id"] }

    assert_includes quote_ids, quotes(:quote_a).id
    assert_not_includes quote_ids, quotes(:quote_b).id
  end

  test "index does not return quote with cross-organization associations" do
    user = users(:owner_a)

    quote = Quote.new(
      organization: organizations(:organization_a),
      customer: customers(:customer_a),
      site: sites(:site_b),
      number: "CROSS-INDEX",
      title: "Cross organization quote",
      issue_date: Date.current
    )

    quote.save(validate: false)

    get "/api/v1/quotes",
        headers: auth_headers(user)

    assert_response :success

    body = JSON.parse(response.body)

    quote_ids = body.map { |item| item["id"] }

    assert_not_includes quote_ids, quote.id
  end

  # ============================================================
  # SHOW
  # ============================================================

  test "user can view quote from same organization" do
    user = users(:owner_a)
    quote = quotes(:quote_a)

    get "/api/v1/quotes/#{quote.id}",
        headers: auth_headers(user)

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal quote.id, body["id"]
    assert_equal quote.number, body["number"]
    assert_equal quote.title, body["title"]
  end

  test "user cannot access quote from another organization" do
    user = users(:owner_a)
    quote = quotes(:quote_b)

    get "/api/v1/quotes/#{quote.id}",
        headers: auth_headers(user)

    assert_response :not_found
  end

  test "show returns not found for unknown quote" do
    user = users(:owner_a)

    get "/api/v1/quotes/#{SecureRandom.uuid}",
        headers: auth_headers(user)

    assert_response :not_found
  end

  # ============================================================
  # CREATE
  # ============================================================

  test "owner can create quote" do
    user = users(:owner_a)
    customer = customers(:customer_a)
    site = sites(:site_a)

    assert_difference("Quote.count", 1) do
      post "/api/v1/quotes",
           params: {
             quote: {
               customer_id: customer.id,
               site_id: site.id,
               number: "DEV-A-0002",
               title: "Nouvelle proposition",
               description: "Nouvelle proposition d'entretien",
               issue_date: "2026-08-25",
               valid_until: "2026-09-25",
               status: "draft",
               notes: "Créée par API",
               subtotal: 1000.00,
               discount_amount: 0.00,
               estimated_cost: 600.00,
               estimated_margin_percentage: 40.00,
               estimated_margin_amount: 400.00,
               tax_amount: 200.00,
               total_amount: 1200.00
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :created

    body = JSON.parse(response.body)

    assert_equal "DEV-A-0002", body["number"]
    assert_equal "Nouvelle proposition", body["title"]
    assert_equal customer.id, body["customer_id"]
    assert_equal site.id, body["site_id"]
    assert_equal user.organization_id, body["organization_id"]
  end

  test "admin can create quote" do
    user = users(:admin_a)

    assert_difference("Quote.count", 1) do
      post "/api/v1/quotes",
           params: {
             quote: {
               customer_id: customers(:customer_a).id,
               site_id: sites(:site_a).id,
               number: "DEV-ADMIN-0001",
               title: "Quote created by admin",
               issue_date: Date.current
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :created
  end

  test "manager can create quote" do
    user = users(:manager_a)

    assert_difference("Quote.count", 1) do
      post "/api/v1/quotes",
           params: {
             quote: {
               customer_id: customers(:customer_a).id,
               site_id: sites(:site_a).id,
               number: "DEV-MANAGER-0001",
               title: "Quote created by manager",
               issue_date: Date.current
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :created
  end

  test "member cannot create quote" do
    user = users(:member_a)

    assert_no_difference("Quote.count") do
      post "/api/v1/quotes",
           params: {
             quote: {
               customer_id: customers(:customer_a).id,
               site_id: sites(:site_a).id,
               number: "DEV-MEMBER-0001",
               title: "Unauthorized quote",
               issue_date: Date.current
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :forbidden
  end

  test "create rejects duplicate number within same organization" do
    user = users(:owner_a)

    assert_no_difference("Quote.count") do
      post "/api/v1/quotes",
           params: {
             quote: {
               customer_id: customers(:customer_a).id,
               site_id: sites(:site_a).id,
               number: quotes(:quote_a).number,
               title: "Duplicate quote",
               issue_date: Date.current
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :unprocessable_entity

    body = JSON.parse(response.body)

    assert_equal "Unprocessable Entity", body["error"]
    assert_includes body["messages"], "Number has already been taken"
  end

  test "create allows same number in another organization" do
    user = users(:owner_a)

    assert_difference("Quote.count", 1) do
      post "/api/v1/quotes",
           params: {
             quote: {
               customer_id: customers(:customer_a).id,
               site_id: sites(:site_a).id,
               number: quotes(:quote_b).number,
               title: "Same number locally",
               issue_date: Date.current
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :created

    body = JSON.parse(response.body)

    assert_equal quotes(:quote_b).number, body["number"]
    assert_equal user.organization_id, body["organization_id"]
  end

  test "create rejects quote without number" do
    user = users(:owner_a)

    assert_no_difference("Quote.count") do
      post "/api/v1/quotes",
           params: {
             quote: {
               customer_id: customers(:customer_a).id,
               site_id: sites(:site_a).id,
               title: "Quote without number",
               issue_date: Date.current
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :unprocessable_entity

    body = JSON.parse(response.body)

    assert_equal "Unprocessable Entity", body["error"]
    assert_includes body["messages"], "Number can't be blank"
  end

  test "create rejects quote without title" do
    user = users(:owner_a)

    assert_no_difference("Quote.count") do
      post "/api/v1/quotes",
           params: {
             quote: {
               customer_id: customers(:customer_a).id,
               site_id: sites(:site_a).id,
               number: "NO-TITLE",
               issue_date: Date.current
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :unprocessable_entity

    body = JSON.parse(response.body)

    assert_equal "Unprocessable Entity", body["error"]
    assert_includes body["messages"], "Title can't be blank"
  end

  test "create rejects quote without issue date" do
    user = users(:owner_a)

    assert_no_difference("Quote.count") do
      post "/api/v1/quotes",
           params: {
             quote: {
               customer_id: customers(:customer_a).id,
               site_id: sites(:site_a).id,
               number: "NO-DATE",
               title: "Quote without date"
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :unprocessable_entity

    body = JSON.parse(response.body)

    assert_equal "Unprocessable Entity", body["error"]
    assert_includes body["messages"], "Issue date can't be blank"
  end

  test "user cannot create quote with customer from another organization" do
    user = users(:owner_a)
    customer = customers(:customer_b)
    site = sites(:site_a)

    assert_no_difference("Quote.count") do
      post "/api/v1/quotes",
         params: {
           quote: {
             customer_id: customer.id,
             site_id: site.id,
             number: "CROSS-CUSTOMER-ORG",
             title: "Invalid quote",
             issue_date: Date.current
           }
         },
         headers: auth_headers(user),
         as: :json
    end

    assert_response :unprocessable_entity

    body = JSON.parse(response.body)

    assert_equal "Unprocessable Entity", body["error"]
    assert_includes body["messages"],
                  "Customer must belong to the same organization"
  end

  test "create rejects quote with site from another organization" do
    user = users(:owner_a)

    assert_no_difference("Quote.count") do
      post "/api/v1/quotes",
           params: {
             quote: {
               customer_id: customers(:customer_a).id,
               site_id: sites(:site_b).id,
               number: "CROSS-SITE",
               title: "Cross organization site",
               issue_date: Date.current
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :unprocessable_entity

    body = JSON.parse(response.body)

    assert_equal "Unprocessable Entity", body["error"]
    assert_includes body["messages"],
                    "Site must belong to the same organization"
  end

  test "create rejects quote with site belonging to another customer" do
    user = users(:owner_a)

    customer = Customer.create!(
      organization: organizations(:organization_a),
      customer_type: :individual,
      first_name: "Other",
      last_name: "Customer"
    )

    assert_no_difference("Quote.count") do
      post "/api/v1/quotes",
           params: {
             quote: {
               customer_id: customer.id,
               site_id: sites(:site_a).id,
               number: "WRONG-CUSTOMER",
               title: "Wrong customer site",
               issue_date: Date.current
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :unprocessable_entity

    body = JSON.parse(response.body)

    assert_equal "Unprocessable Entity", body["error"]
    assert_includes body["messages"],
                    "Site must belong to the selected customer"
  end

  # ============================================================
  # UPDATE
  # ============================================================

  test "owner can update quote" do
    user = users(:owner_a)
    quote = quotes(:quote_a)

    patch "/api/v1/quotes/#{quote.id}",
          params: {
            quote: {
              title: "Updated quote title",
              notes: "Updated through API"
            }
          },
          headers: auth_headers(user),
          as: :json

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal "Updated quote title", body["title"]
    assert_equal "Updated through API", body["notes"]
  end

  test "admin can update quote" do
    user = users(:admin_a)
    quote = quotes(:quote_a)

    patch "/api/v1/quotes/#{quote.id}",
          params: {
            quote: {
              title: "Updated by admin"
            }
          },
          headers: auth_headers(user),
          as: :json

    assert_response :success
  end

  test "manager can update quote" do
    user = users(:manager_a)
    quote = quotes(:quote_a)

    patch "/api/v1/quotes/#{quote.id}",
          params: {
            quote: {
              title: "Updated by manager"
            }
          },
          headers: auth_headers(user),
          as: :json

    assert_response :success
  end

  test "member cannot update quote" do
    user = users(:member_a)
    quote = quotes(:quote_a)

    original_title = quote.title

    patch "/api/v1/quotes/#{quote.id}",
          params: {
            quote: {
              title: "Unauthorized update"
            }
          },
          headers: auth_headers(user),
          as: :json

    assert_response :forbidden

    assert_equal original_title, quote.reload.title
  end

  test "user cannot update quote from another organization" do
    user = users(:owner_a)
    quote = quotes(:quote_b)

    patch "/api/v1/quotes/#{quote.id}",
          params: {
            quote: {
              title: "Cross organization update"
            }
          },
          headers: auth_headers(user),
          as: :json

    assert_response :not_found
  end

  test "update rejects duplicate number within same organization" do
    user = users(:owner_a)

    another_quote = Quote.create!(
      organization: organizations(:organization_a),
      customer: customers(:customer_a),
      site: sites(:site_a),
      number: "DEV-A-0002",
      title: "Another quote",
      issue_date: Date.current
    )

    patch "/api/v1/quotes/#{another_quote.id}",
          params: {
            quote: {
              number: quotes(:quote_a).number
            }
          },
          headers: auth_headers(user),
          as: :json

    assert_response :unprocessable_entity

    body = JSON.parse(response.body)

    assert_equal "Unprocessable Entity", body["error"]
    assert_includes body["messages"], "Number has already been taken"

    assert_equal "DEV-A-0002", another_quote.reload.number
  end

  test "user cannot move quote to customer from another organization" do
    user = users(:owner_a)
    quote = quotes(:quote_a)

    original_customer_id = quote.customer_id

    patch "/api/v1/quotes/#{quote.id}",
          params: {
            quote: {
              customer_id: customers(:customer_b).id
            }
          },
          headers: auth_headers(user),
          as: :json

    assert_response :unprocessable_entity

    body = JSON.parse(response.body)

    assert_equal "Unprocessable Entity", body["error"]
    assert_includes body["messages"],
                    "Customer must belong to the same organization"

    assert_equal original_customer_id, quote.reload.customer_id
  end

  test "user cannot move quote to site from another organization" do
    user = users(:owner_a)
    quote = quotes(:quote_a)

    original_site_id = quote.site_id

    patch "/api/v1/quotes/#{quote.id}",
          params: {
            quote: {
              site_id: sites(:site_b).id
            }
          },
          headers: auth_headers(user),
          as: :json

    assert_response :unprocessable_entity

    body = JSON.parse(response.body)

    assert_equal "Unprocessable Entity", body["error"]
    assert_includes body["messages"],
                    "Site must belong to the same organization"

    assert_equal original_site_id, quote.reload.site_id
  end

  test "user cannot move quote to site belonging to another customer" do
    user = users(:owner_a)
    quote = quotes(:quote_a)

    other_customer = Customer.create!(
      organization: organizations(:organization_a),
      customer_type: :individual,
      first_name: "Other",
      last_name: "Customer"
    )

    other_site = Site.create!(
      organization: organizations(:organization_a),
      customer: other_customer,
      name: "Other customer site"
    )

    original_site_id = quote.site_id

    patch "/api/v1/quotes/#{quote.id}",
          params: {
            quote: {
              site_id: other_site.id
            }
          },
          headers: auth_headers(user),
          as: :json

    assert_response :unprocessable_entity

    body = JSON.parse(response.body)

    assert_equal "Unprocessable Entity", body["error"]
    assert_includes body["messages"],
                    "Site must belong to the selected customer"

    assert_equal original_site_id, quote.reload.site_id
  end

  # ============================================================
  # DELETE
  # ============================================================

  test "owner can destroy quote" do
    user = users(:owner_a)

    quote = Quote.create!(
      organization: user.organization,
      customer: customers(:customer_a),
      site: sites(:site_a),
      number: "DELETE-OWNER",
      title: "Quote to delete",
      issue_date: Date.current
    )

    assert_difference("Quote.count", -1) do
      delete "/api/v1/quotes/#{quote.id}",
             headers: auth_headers(user)
    end

    assert_response :no_content
  end

  test "admin can destroy quote" do
    user = users(:admin_a)

    quote = Quote.create!(
      organization: user.organization,
      customer: customers(:customer_a),
      site: sites(:site_a),
      number: "DELETE-ADMIN",
      title: "Quote to delete",
      issue_date: Date.current
    )

    assert_difference("Quote.count", -1) do
      delete "/api/v1/quotes/#{quote.id}",
             headers: auth_headers(user)
    end

    assert_response :no_content
  end

  test "manager cannot destroy quote" do
    user = users(:manager_a)
    quote = quotes(:quote_a)

    assert_no_difference("Quote.count") do
      delete "/api/v1/quotes/#{quote.id}",
             headers: auth_headers(user)
    end

    assert_response :forbidden
  end

  test "member cannot destroy quote" do
    user = users(:member_a)
    quote = quotes(:quote_a)

    assert_no_difference("Quote.count") do
      delete "/api/v1/quotes/#{quote.id}",
             headers: auth_headers(user)
    end

    assert_response :forbidden
  end

  test "user cannot destroy quote from another organization" do
    user = users(:owner_a)
    quote = quotes(:quote_b)

    assert_no_difference("Quote.count") do
      delete "/api/v1/quotes/#{quote.id}",
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
