
require "test_helper"

class Api::V1::SitesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organization = Organization.create!(
      name: "GreenPilot Sites Test",
      slug: "greenpilot-sites-test"
    )

    @other_organization = Organization.create!(
      name: "Other Organization",
      slug: "other-organization-sites-test"
    )

    @owner = create_user(
      organization: @organization,
      email: "owner-sites@example.com",
      role: "owner"
    )

    @admin = create_user(
      organization: @organization,
      email: "admin-sites@example.com",
      role: "admin"
    )

    @manager = create_user(
      organization: @organization,
      email: "manager-sites@example.com",
      role: "manager"
    )

    @accountant = create_user(
      organization: @organization,
      email: "accountant-sites@example.com",
      role: "accountant"
    )

    @field_worker = create_user(
      organization: @organization,
      email: "field-worker-sites@example.com",
      role: "field_worker"
    )

    @member = create_user(
      organization: @organization,
      email: "member-sites@example.com",
      role: "member"
    )

    @other_manager = create_user(
      organization: @other_organization,
      email: "other-manager-sites@example.com",
      role: "manager"
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
      email: "other-customer-sites@example.com"
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

    @owner_token = JwtService.encode(@owner)
    @admin_token = JwtService.encode(@admin)
    @manager_token = JwtService.encode(@manager)
    @accountant_token = JwtService.encode(@accountant)
    @field_worker_token = JwtService.encode(@field_worker)
    @member_token = JwtService.encode(@member)
    @other_manager_token = JwtService.encode(@other_manager)
  end

  test "index requires authentication" do
    get "/api/v1/sites"

    assert_response :unauthorized
  end

  test "index returns sites from authenticated user's organization" do
    get "/api/v1/sites",
        headers: auth_headers(@manager_token)

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal 1, body.length
    assert_equal @site.id, body.first["id"]
  end

  test "index does not expose sites from another organization" do
    get "/api/v1/sites",
        headers: auth_headers(@manager_token)

    assert_response :success

    body = JSON.parse(response.body)

    assert body.none? { |site| site["id"] == @other_site.id }
  end

  test "show returns site from same organization" do
    get "/api/v1/sites/#{@site.id}",
        headers: auth_headers(@manager_token)

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal @site.id, body["id"]
    assert_equal @customer.id, body["customer_id"]
    assert_equal @organization.id, body["organization_id"]
  end

  test "show does not expose site from another organization" do
    get "/api/v1/sites/#{@other_site.id}",
        headers: auth_headers(@manager_token)

    assert_response :not_found

    body = JSON.parse(response.body)

    assert_equal "Not Found", body["error"]
  end

  test "show returns not found for a nonexistent site" do
    get "/api/v1/sites/00000000-0000-0000-0000-000000000000",
        headers: auth_headers(@manager_token)

    assert_response :not_found
  end

  test "owner can create site" do
    assert_difference("Site.count", 1) do
      post "/api/v1/sites",
           params: {
             site: {
               customer_id: @customer.id,
               name: "Nouveau jardin owner",
               site_type: "garden",
               city: "Strasbourg",
               country: "FR"
             }
           },
           headers: auth_headers(@owner_token)
    end

    assert_response :created

    body = JSON.parse(response.body)

    assert_equal "Nouveau jardin owner", body["name"]
    assert_equal @customer.id, body["customer_id"]
    assert_equal @organization.id, body["organization_id"]
  end

  test "admin can create site" do
    assert_difference("Site.count", 1) do
      post "/api/v1/sites",
           params: {
             site: {
               customer_id: @customer.id,
               name: "Nouveau jardin admin",
               site_type: "garden"
             }
           },
           headers: auth_headers(@admin_token)
    end

    assert_response :created
  end

  test "manager can create site" do
    assert_difference("Site.count", 1) do
      post "/api/v1/sites",
           params: {
             site: {
               customer_id: @customer.id,
               name: "Nouveau jardin manager",
               site_type: "garden",
               address_line1: "20 rue des Fleurs",
               postal_code: "67100",
               city: "Strasbourg",
               country: "FR",
               surface_area: 750.0
             }
           },
           headers: auth_headers(@manager_token)
    end

    assert_response :created

    body = JSON.parse(response.body)

    assert_equal "Nouveau jardin manager", body["name"]
    assert_equal @customer.id, body["customer_id"]
    assert_equal @organization.id, body["organization_id"]
  end

  test "accountant cannot create site" do
    assert_no_difference("Site.count") do
      post "/api/v1/sites",
           params: {
             site: {
               customer_id: @customer.id,
               name: "Unauthorized accountant",
               site_type: "garden"
             }
           },
           headers: auth_headers(@accountant_token)
    end

    assert_response :forbidden
  end

  test "field worker cannot create site" do
    assert_no_difference("Site.count") do
      post "/api/v1/sites",
           params: {
             site: {
               customer_id: @customer.id,
               name: "Unauthorized field worker",
               site_type: "garden"
             }
           },
           headers: auth_headers(@field_worker_token)
    end

    assert_response :forbidden
  end

  test "member cannot create site" do
    assert_no_difference("Site.count") do
      post "/api/v1/sites",
           params: {
             site: {
               customer_id: @customer.id,
               name: "Unauthorized member",
               site_type: "garden"
             }
           },
           headers: auth_headers(@member_token)
    end

    assert_response :forbidden
  end

  test "manager cannot create site for customer from another organization" do
    assert_no_difference("Site.count") do
      post "/api/v1/sites",
           params: {
             site: {
               customer_id: @other_customer.id,
               name: "Cross organization site",
               site_type: "garden",
               city: "Colmar",
               country: "FR"
             }
           },
           headers: auth_headers(@manager_token)
    end

    assert_response :forbidden
  end

  test "create returns unprocessable entity for invalid site" do
    assert_no_difference("Site.count") do
      post "/api/v1/sites",
           params: {
             site: {
               customer_id: @customer.id
             }
           },
           headers: auth_headers(@manager_token)
    end

    assert_response :unprocessable_entity

    body = JSON.parse(response.body)

    assert_equal "Unprocessable Entity", body["error"]
    assert body["messages"].any?
  end

  test "create ignores organization_id supplied by client" do
    assert_difference("Site.count", 1) do
      post "/api/v1/sites",
           params: {
             site: {
               organization_id: @other_organization.id,
               customer_id: @customer.id,
               name: "Tenant isolation site",
               site_type: "garden"
             }
           },
           headers: auth_headers(@manager_token)
    end

    assert_response :created

    site = Site.order(created_at: :desc).first

    assert_equal @organization.id, site.organization_id
    assert_equal @customer.id, site.customer_id
  end

  test "owner can update site from same organization" do
    patch "/api/v1/sites/#{@site.id}",
          params: {
            site: {
              name: "Jardin rénové owner",
              surface_area: 600.0
            }
          },
          headers: auth_headers(@owner_token)

    assert_response :success

    @site.reload

    assert_equal "Jardin rénové owner", @site.name
    assert_equal 600.0, @site.surface_area.to_f
  end

  test "admin can update site from same organization" do
    patch "/api/v1/sites/#{@site.id}",
          params: {
            site: {
              name: "Jardin rénové admin"
            }
          },
          headers: auth_headers(@admin_token)

    assert_response :success

    assert_equal "Jardin rénové admin", @site.reload.name
  end

  test "manager can update site from same organization" do
    patch "/api/v1/sites/#{@site.id}",
          params: {
            site: {
              name: "Jardin rénové manager",
              surface_area: 600.0
            }
          },
          headers: auth_headers(@manager_token)

    assert_response :success

    @site.reload

    assert_equal "Jardin rénové manager", @site.name
    assert_equal 600.0, @site.surface_area.to_f
  end

  test "accountant cannot update site" do
    patch "/api/v1/sites/#{@site.id}",
          params: {
            site: {
              name: "Unauthorized accountant"
            }
          },
          headers: auth_headers(@accountant_token)

    assert_response :forbidden

    assert_equal "Jardin principal", @site.reload.name
  end

  test "field worker cannot update site" do
    patch "/api/v1/sites/#{@site.id}",
          params: {
            site: {
              name: "Unauthorized field worker"
            }
          },
          headers: auth_headers(@field_worker_token)

    assert_response :forbidden

    assert_equal "Jardin principal", @site.reload.name
  end

  test "member cannot update site" do
    patch "/api/v1/sites/#{@site.id}",
          params: {
            site: {
              name: "Unauthorized member"
            }
          },
          headers: auth_headers(@member_token)

    assert_response :forbidden

    assert_equal "Jardin principal", @site.reload.name
  end

  test "manager cannot update site from another organization" do
    patch "/api/v1/sites/#{@other_site.id}",
          params: {
            site: {
              name: "Unauthorized update"
            }
          },
          headers: auth_headers(@manager_token)

    assert_response :not_found

    assert_equal "Other Garden", @other_site.reload.name
  end

  test "owner cannot update site from another organization" do
    patch "/api/v1/sites/#{@other_site.id}",
          params: {
            site: {
              name: "Unauthorized owner update"
            }
          },
          headers: auth_headers(@owner_token)

    assert_response :not_found

    assert_equal "Other Garden", @other_site.reload.name
  end

  test "manager cannot update site with customer from another organization" do
    patch "/api/v1/sites/#{@site.id}",
          params: {
            site: {
              customer_id: @other_customer.id
            }
          },
          headers: auth_headers(@manager_token)

    assert_response :unprocessable_entity

    body = JSON.parse(response.body)

    assert_equal "Unprocessable Entity", body["error"]
    assert body["messages"].any?

    assert_equal @customer.id, @site.reload.customer_id
  end

  test "manager cannot update site with organization_id from another organization" do
    patch "/api/v1/sites/#{@site.id}",
          params: {
            site: {
              organization_id: @other_organization.id,
              name: "Attempted tenant switch"
            }
          },
          headers: auth_headers(@manager_token)

    assert_response :success

    site = @site.reload

    assert_equal "Attempted tenant switch", site.name
    assert_equal @organization.id, site.organization_id
  end

  test "update returns unprocessable entity for invalid site" do
    patch "/api/v1/sites/#{@site.id}",
          params: {
            site: {
              name: ""
            }
          },
          headers: auth_headers(@manager_token)

    assert_response :unprocessable_entity

    body = JSON.parse(response.body)

    assert_equal "Unprocessable Entity", body["error"]
    assert body["messages"].any?

    assert_equal "Jardin principal", @site.reload.name
  end

  test "update returns not found for a nonexistent site" do
    patch "/api/v1/sites/00000000-0000-0000-0000-000000000000",
          params: {
            site: {
              name: "Updated"
            }
          },
          headers: auth_headers(@manager_token)

    assert_response :not_found
  end

  test "owner can destroy site" do
    assert_difference("Site.count", -1) do
      delete "/api/v1/sites/#{@site.id}",
             headers: auth_headers(@owner_token)
    end

    assert_response :no_content
  end

  test "admin can destroy site" do
    site = Site.create!(
      organization: @organization,
      customer: @customer,
      name: "Admin Delete Site"
    )

    assert_difference("Site.count", -1) do
      delete "/api/v1/sites/#{site.id}",
             headers: auth_headers(@admin_token)
    end

    assert_response :no_content
  end

  test "manager cannot destroy site" do
    assert_no_difference("Site.count") do
      delete "/api/v1/sites/#{@site.id}",
             headers: auth_headers(@manager_token)
    end

    assert_response :forbidden
  end

  test "accountant cannot destroy site" do
    assert_no_difference("Site.count") do
      delete "/api/v1/sites/#{@site.id}",
             headers: auth_headers(@accountant_token)
    end

    assert_response :forbidden
  end

  test "field worker cannot destroy site" do
    assert_no_difference("Site.count") do
      delete "/api/v1/sites/#{@site.id}",
             headers: auth_headers(@field_worker_token)
    end

    assert_response :forbidden
  end

  test "member cannot destroy site" do
    assert_no_difference("Site.count") do
      delete "/api/v1/sites/#{@site.id}",
             headers: auth_headers(@member_token)
    end

    assert_response :forbidden
  end

  test "owner cannot destroy site from another organization" do
    assert_no_difference("Site.count") do
      delete "/api/v1/sites/#{@other_site.id}",
             headers: auth_headers(@owner_token)
    end

    assert_response :not_found

    assert Site.exists?(@other_site.id)
  end

  test "destroy returns not found for a nonexistent site" do
    delete "/api/v1/sites/00000000-0000-0000-0000-000000000000",
           headers: auth_headers(@owner_token)

    assert_response :not_found
  end

  private

  def create_user(organization:, email:, role:)
    User.create!(
      organization: organization,
      email: email,
      password: "password123",
      password_confirmation: "password123",
      first_name: "Test",
      last_name: "User",
      role: role
    )
  end

  def auth_headers(token)
    {
      "Authorization" => "Bearer #{token}"
    }
  end
end