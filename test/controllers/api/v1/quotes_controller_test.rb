require "test_helper"

class Api::V1::QuotesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organization = Organization.create!(
      name: "GreenPilot Quotes Test",
      slug: "greenpilot-quotes-test"
    )

    @other_organization = Organization.create!(
      name: "Other Quotes Organization",
      slug: "other-quotes-org"
    )

    @manager = User.create!(
      organization: @organization,
      email: "manager-quotes@example.com",
      first_name: "Quote",
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
      email: "john-quotes@example.com"
    )

    @other_customer = Customer.create!(
      organization: @other_organization,
      customer_type: "individual",
      first_name: "Other",
      last_name: "Customer",
      email: "other-quotes@example.com"
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

    @quote = Quote.create!(
      organization: @organization,
      customer: @customer,
      site: @site,
      number: "DEV-2026-0001",
      title: "Entretien annuel",
      description: "Contrat annuel d'entretien",
      issue_date: Date.current,
      valid_until: Date.current + 30.days,
      status: "draft"
    )

    @other_quote = Quote.create!(
      organization: @other_organization,
      customer: @other_customer,
      site: @other_site,
      number: "DEV-OTHER-0001",
      title: "Other Quote",
      issue_date: Date.current,
      status: "draft"
    )

    @token = JwtService.encode(@manager)
  end

  test "index requires authentication" do
    get "/api/v1/quotes"

    assert_response :unauthorized
  end

  test "index returns quotes from authenticated user's organization" do
    get "/api/v1/quotes",
        headers: {
          "Authorization" => "Bearer #{@token}"
        }

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal 1, body.length
    assert_equal @quote.id, body.first["id"]
  end

  test "show returns quote from same organization" do
    get "/api/v1/quotes/#{@quote.id}",
        headers: {
          "Authorization" => "Bearer #{@token}"
        }

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal @quote.id, body["id"]
    assert_equal "DEV-2026-0001", body["number"]
    assert_equal @customer.id, body["customer_id"]
    assert_equal @site.id, body["site_id"]
  end

  test "show does not expose quote from another organization" do
    get "/api/v1/quotes/#{@other_quote.id}",
        headers: {
          "Authorization" => "Bearer #{@token}"
        }

    assert_response :not_found
  end

  test "manager can create quote" do
    assert_difference("Quote.count", 1) do
      post "/api/v1/quotes",
           params: {
             quote: {
               customer_id: @customer.id,
               site_id: @site.id,
               number: "DEV-2026-0002",
               title: "Nouvel entretien",
               description: "Devis pour entretien",
               issue_date: Date.current,
               valid_until: Date.current + 30.days,
               status: "draft"
             }
           },
           headers: {
             "Authorization" => "Bearer #{@token}"
           }
    end

    assert_response :created

    body = JSON.parse(response.body)

    assert_equal "DEV-2026-0002", body["number"]
    assert_equal "Nouvel entretien", body["title"]
    assert_equal @customer.id, body["customer_id"]
    assert_equal @site.id, body["site_id"]
    assert_equal @organization.id, body["organization_id"]
  end

  test "manager cannot create quote with customer from another organization" do
    assert_no_difference("Quote.count") do
      post "/api/v1/quotes",
           params: {
             quote: {
               customer_id: @other_customer.id,
               site_id: @site.id,
               number: "DEV-HACK-CUSTOMER",
               title: "Invalid Customer Quote",
               issue_date: Date.current
             }
           },
           headers: {
             "Authorization" => "Bearer #{@token}"
           }
    end

    assert_response :forbidden
  end

  test "manager cannot create quote with site from another organization" do
    assert_no_difference("Quote.count") do
      post "/api/v1/quotes",
           params: {
             quote: {
               customer_id: @customer.id,
               site_id: @other_site.id,
               number: "DEV-HACK-SITE",
               title: "Invalid Site Quote",
               issue_date: Date.current
             }
           },
           headers: {
             "Authorization" => "Bearer #{@token}"
           }
    end

    assert_response :forbidden
  end

  test "manager can update quote" do
    patch "/api/v1/quotes/#{@quote.id}",
          params: {
            quote: {
              title: "Entretien annuel mis à jour",
              description: "Description mise à jour",
              valid_until: Date.current + 45.days
            }
          },
          headers: {
            "Authorization" => "Bearer #{@token}"
          }

    assert_response :success

    @quote.reload

    assert_equal "Entretien annuel mis à jour", @quote.title
    assert_equal "Description mise à jour", @quote.description
    assert_equal Date.current + 45.days, @quote.valid_until
  end

  test "manager cannot update quote from another organization" do
    patch "/api/v1/quotes/#{@other_quote.id}",
          params: {
            quote: {
              title: "Unauthorized update"
            }
          },
          headers: {
            "Authorization" => "Bearer #{@token}"
          }

    assert_response :not_found

    assert_equal "Other Quote", @other_quote.reload.title
  end

  test "duplicate quote number is rejected within organization" do
    assert_no_difference("Quote.count") do
      post "/api/v1/quotes",
           params: {
             quote: {
               customer_id: @customer.id,
               site_id: @site.id,
               number: "DEV-2026-0001",
               title: "Duplicate Quote",
               issue_date: Date.current
             }
           },
           headers: {
             "Authorization" => "Bearer #{@token}"
           }
    end

    assert_response :unprocessable_entity

    body = JSON.parse(response.body)

    assert body["messages"].any? { |message| message.include?("Number") }
  end
end