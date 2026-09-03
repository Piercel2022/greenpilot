require "test_helper"

class Api::V1::QuoteItemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organization = Organization.create!(
      name: "GreenPilot Quote Items Test",
      slug: "greenpilot-quote-items-test"
    )

    @other_organization = Organization.create!(
      name: "Other Quote Items Organization",
      slug: "other-quote-items-org"
    )

    @manager = User.create!(
      organization: @organization,
      email: "manager-quote-items@example.com",
      first_name: "Quote",
      last_name: "Item Manager",
      role: "manager",
      password: "password123",
      password_confirmation: "password123"
    )

    @customer = Customer.create!(
      organization: @organization,
      customer_type: "individual",
      first_name: "John",
      last_name: "Customer",
      email: "john-quote-items@example.com"
    )

    @other_customer = Customer.create!(
      organization: @other_organization,
      customer_type: "individual",
      first_name: "Other",
      last_name: "Customer",
      email: "other-quote-items@example.com"
    )

    @site = Site.create!(
      organization: @organization,
      customer: @customer,
      name: "Jardin principal",
      address_line1: "10 rue des Jardins",
      city: "Strasbourg",
      postal_code: "67000",
      country: "FR"
    )

    @other_site = Site.create!(
      organization: @other_organization,
      customer: @other_customer,
      name: "Other Site",
      address_line1: "20 Other Street",
      city: "Colmar",
      postal_code: "68000",
      country: "FR"
    )

    @category = ServiceCategory.create!(
      organization: @organization,
      code: "ENT",
      name: "Entretien",
      position: 1
    )

    @other_category = ServiceCategory.create!(
      organization: @other_organization,
      code: "OTH",
      name: "Other Services",
      position: 1
    )

    @service_item = ServiceItem.create!(
      organization: @organization,
      service_category: @category,
      code: "TONTE",
      name: "Tonte de pelouse",
      position: 1
    )

    @other_service_item = ServiceItem.create!(
      organization: @other_organization,
      service_category: @other_category,
      code: "OTHER",
      name: "Other Service",
      position: 1
    )

    @quote = Quote.create!(
      organization: @organization,
      customer: @customer,
      site: @site,
      number: "DEV-QI-0001",
      title: "Entretien annuel",
      issue_date: Date.current,
      status: "draft"
    )

    @other_quote = Quote.create!(
      organization: @other_organization,
      customer: @other_customer,
      site: @other_site,
      number: "DEV-QI-OTHER-0001",
      title: "Other Quote",
      issue_date: Date.current,
      status: "draft"
    )

    @quote_item = QuoteItem.create!(
      quote: @quote,
      service_item: @service_item,
      description: "Tonte de pelouse",
      quantity: 2.0,
      unit: "hour",
      unit_price: 45.0,
      discount_percentage: 0.0,
      tax_rate: 20.0,
      position: 1
    )

    @other_quote_item = QuoteItem.create!(
      quote: @other_quote,
      service_item: @other_service_item,
      description: "Other service",
      quantity: 1.0,
      unit: "unit",
      unit_price: 100.0,
      discount_percentage: 0.0,
      tax_rate: 20.0,
      position: 1
    )

    @token = JwtService.encode(@manager)
  end

  test "index requires authentication" do
    get "/api/v1/quote_items"

    assert_response :unauthorized
  end

  test "index returns quote items from authenticated user's organization" do
    get "/api/v1/quote_items",
        headers: {
          "Authorization" => "Bearer #{@token}"
        }

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal 1, body.length
    assert_equal @quote_item.id, body.first["id"]
  end

  test "show returns quote item from same organization" do
    get "/api/v1/quote_items/#{@quote_item.id}",
        headers: {
          "Authorization" => "Bearer #{@token}"
        }

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal @quote_item.id, body["id"]
    assert_equal @quote.id, body["quote_id"]
    assert_equal @service_item.id, body["service_item_id"]
  end

  test "show does not expose quote item from another organization" do
    get "/api/v1/quote_items/#{@other_quote_item.id}",
        headers: {
          "Authorization" => "Bearer #{@token}"
        }

    assert_response :not_found
  end

  test "manager can create quote item" do
    assert_difference("QuoteItem.count", 1) do
      post "/api/v1/quote_items",
           params: {
             quote_item: {
               quote_id: @quote.id,
               service_item_id: @service_item.id,
               description: "Tonte supplémentaire",
               quantity: 3.0,
               unit: "hour",
               unit_price: 50.0,
               discount_percentage: 5.0,
               tax_rate: 20.0,
               position: 2
             }
           },
           headers: {
             "Authorization" => "Bearer #{@token}"
           }
    end

    assert_response :created

    body = JSON.parse(response.body)

    assert_equal @quote.id, body["quote_id"]
    assert_equal @service_item.id, body["service_item_id"]
    assert_equal "Tonte supplémentaire", body["description"]
    assert_equal 3.0, body["quantity"].to_f
  end

  test "manager cannot create quote item for quote from another organization" do
    assert_no_difference("QuoteItem.count") do
      post "/api/v1/quote_items",
           params: {
             quote_item: {
               quote_id: @other_quote.id,
               service_item_id: @service_item.id,
               description: "Invalid quote",
               quantity: 1.0,
               unit_price: 50.0
             }
           },
           headers: {
             "Authorization" => "Bearer #{@token}"
           }
    end

    assert_response :forbidden
  end

  test "manager cannot create quote item with service item from another organization" do
    assert_no_difference("QuoteItem.count") do
      post "/api/v1/quote_items",
           params: {
             quote_item: {
               quote_id: @quote.id,
               service_item_id: @other_service_item.id,
               description: "Invalid service item",
               quantity: 1.0,
               unit_price: 50.0
             }
           },
           headers: {
             "Authorization" => "Bearer #{@token}"
           }
    end

    assert_response :forbidden
  end

  test "manager can update quote item" do
    patch "/api/v1/quote_items/#{@quote_item.id}",
          params: {
            quote_item: {
              description: "Tonte professionnelle",
              quantity: 4.0,
              unit_price: 55.0
            }
          },
          headers: {
            "Authorization" => "Bearer #{@token}"
          }

    assert_response :success

    @quote_item.reload

    assert_equal "Tonte professionnelle", @quote_item.description
    assert_equal 4.0, @quote_item.quantity.to_f
    assert_equal 55.0, @quote_item.unit_price.to_f
  end

  test "manager cannot update quote item from another organization" do
    patch "/api/v1/quote_items/#{@other_quote_item.id}",
          params: {
            quote_item: {
              description: "Unauthorized update"
            }
          },
          headers: {
            "Authorization" => "Bearer #{@token}"
          }

    assert_response :not_found

    assert_equal "Other service", @other_quote_item.reload.description
  end

  test "invalid quantity is rejected" do
    assert_no_difference("QuoteItem.count") do
      post "/api/v1/quote_items",
           params: {
             quote_item: {
               quote_id: @quote.id,
               service_item_id: @service_item.id,
               description: "Invalid quantity",
               quantity: 0,
               unit_price: 50.0
             }
           },
           headers: {
             "Authorization" => "Bearer #{@token}"
           }
    end

    assert_response :unprocessable_entity
  end

  test "invalid discount percentage is rejected" do
    assert_no_difference("QuoteItem.count") do
      post "/api/v1/quote_items",
           params: {
             quote_item: {
               quote_id: @quote.id,
               service_item_id: @service_item.id,
               description: "Invalid discount",
               quantity: 1.0,
               unit_price: 50.0,
               discount_percentage: 101
             }
           },
           headers: {
             "Authorization" => "Bearer #{@token}"
           }
    end

    assert_response :unprocessable_entity
  end
test "GET /quote_items does not expose quote items from another organization" do
  owner_b = users(:owner_b)

  get api_v1_quote_items_path,
      headers: auth_headers(owner_b),
      as: :json

  assert_response :success

  body = JSON.parse(response.body)

  refute body.any? { |item| item["id"] == quote_items(:quote_item_a).id }
  assert body.any? { |item| item["id"] == quote_items(:quote_item_b).id }
end

test "PATCH /quote_items cannot modify quote item from another organization" do
  owner_b = users(:owner_b)
  quote_item_a = quote_items(:quote_item_a)

  patch api_v1_quote_item_path(quote_item_a),
        params: {
          quote_item: {
            description: "Hacked item"
          }
        },
        headers: auth_headers(owner_b),
        as: :json

  assert_response :not_found

  quote_item_a.reload
  refute_equal "Hacked item", quote_item_a.description
end

test "manager cannot update quote item to quote from another organization" do
  patch "/api/v1/quote_items/#{@quote_item.id}",
        params: {
          quote_item: {
            quote_id: @other_quote.id
          }
        },
        headers: {
          "Authorization" => "Bearer #{@token}"
        }

  assert_response :unprocessable_entity

  body = JSON.parse(response.body)

  assert_includes body["messages"], "Quote must belong to the same organization"
  assert_equal @quote.id, @quote_item.reload.quote_id
end
  
end