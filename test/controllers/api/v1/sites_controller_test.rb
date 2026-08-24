require "test_helper"

class Api::V1::SitesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organization = Organization.create!(
      name: "GreenPilot Sites Test",
      slug: "greenpilot-sites-test"
    )

    @other_organization = Organization.create!(
      name: "Other Organization",
      slug: "other-organization"
    )

    @manager = User.create!(
      organization: @organization,
      email: "manager-sites@example.com",
      first_name: "Sites",
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
      email: "john-sites@example.com"
    )

    @other_customer = Customer.create!(
      organization: @other_organization,
      customer_type: "individual",
      first_name: "Other",
      last_name: "Customer",
      email: "other-sites@example.com"
    )

    @site = Site.create!(
      organization: @organization,
      customer: @customer,
      name: "Jardin principal",
      site_type: "garden",
      address_line1: "10 rue des Jardins",
      postal_code: "67000",
      city: "Strasbourg",
      country: "FR",
      surface_area: 500.0
    )

    @other_site = Site.create!(
      organization: @other_organization,
      customer: @other_customer,
      name: "Other Garden",
      site_type: "garden",
      city: "Colmar",
      country: "FR"
    )

    @token = JwtService.encode(@manager)
  end

  test "index requires authentication" do
    get "/api/v1/sites"

    assert_response :unauthorized
  end

  test "index returns sites from authenticated user's organization" do
    get "/api/v1/sites",
        headers: {
          "Authorization" => "Bearer #{@token}"
        }

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal 1, body.length
    assert_equal @site.id, body.first["id"]
  end

  test "show returns site from same organization" do
    get "/api/v1/sites/#{@site.id}",
        headers: {
          "Authorization" => "Bearer #{@token}"
        }

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal @site.id, body["id"]
    assert_equal @customer.id, body["customer_id"]
  end

  test "show does not expose site from another organization" do
    get "/api/v1/sites/#{@other_site.id}",
        headers: {
          "Authorization" => "Bearer #{@token}"
        }

    assert_response :not_found
  end

  test "manager can create site" do
    assert_difference("Site.count", 1) do
      post "/api/v1/sites",
           params: {
             site: {
               customer_id: @customer.id,
               name: "Nouveau jardin",
               site_type: "garden",
               address_line1: "20 rue des Fleurs",
               postal_code: "67100",
               city: "Strasbourg",
               country: "FR",
               surface_area: 750.0
             }
           },
           headers: {
             "Authorization" => "Bearer #{@token}"
           }
    end

    assert_response :created

    body = JSON.parse(response.body)

    assert_equal "Nouveau jardin", body["name"]
    assert_equal @customer.id, body["customer_id"]
    assert_equal @organization.id, body["organization_id"]
  end

  test "manager cannot create site for customer from another organization" do
    assert_no_difference("Site.count") do
      post "/api/v1/sites",
           params: {
             site: {
               customer_id: @other_customer.id,
               name: "Invalid Site",
               site_type: "garden",
               city: "Colmar",
               country: "FR"
             }
           },
           headers: {
             "Authorization" => "Bearer #{@token}"
           }
    end

    assert_response :forbidden
  end

  test "manager can update site" do
    patch "/api/v1/sites/#{@site.id}",
          params: {
            site: {
              name: "Jardin principal rénové",
              surface_area: 600.0
            }
          },
          headers: {
            "Authorization" => "Bearer #{@token}"
          }

    assert_response :success

    @site.reload

    assert_equal "Jardin principal rénové", @site.name
    assert_equal 600.0, @site.surface_area.to_f
  end

  test "manager cannot update site from another organization" do
    patch "/api/v1/sites/#{@other_site.id}",
          params: {
            site: {
              name: "Unauthorized update"
            }
          },
          headers: {
            "Authorization" => "Bearer #{@token}"
          }

    assert_response :not_found

    assert_equal "Other Garden", @other_site.reload.name
  end
end