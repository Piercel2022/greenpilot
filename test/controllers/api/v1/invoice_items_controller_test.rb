require "test_helper"

class Api::V1::InvoiceItemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organization = Organization.create!(
      name: "GreenPilot Invoice Items Test",
      slug: "greenpilot-invoice-items-test"
    )

    @other_organization = Organization.create!(
      name: "Other Invoice Items Organization",
      slug: "other-invoice-items-test"
    )

    @manager = create_user(
      organization: @organization,
      email: "manager-invoice-items@example.com",
      role: "manager"
    )

    @owner = create_user(
      organization: @organization,
      email: "owner-invoice-items@example.com",
      role: "owner"
    )

    @member = create_user(
      organization: @organization,
      email: "member-invoice-items@example.com",
      role: "member"
    )

    @other_manager = create_user(
      organization: @other_organization,
      email: "other-manager-invoice-items@example.com",
      role: "manager"
    )

    @customer = Customer.create!(
      organization: @organization,
      customer_type: "individual",
      first_name: "John",
      last_name: "Customer",
      email: "john-invoice-items@example.com"
    )

    @other_customer = Customer.create!(
      organization: @other_organization,
      customer_type: "individual",
      first_name: "Other",
      last_name: "Customer",
      email: "other-invoice-items@example.com"
    )

    @invoice = Invoice.create!(
      organization: @organization,
      customer: @customer,
      number: "INV-ITEM-001",
      issue_date: Date.current,
      status: "draft",
      subtotal: 100.0,
      tax_amount: 20.0,
      total_amount: 120.0,
      amount_paid: 0.0,
      amount_due: 120.0
    )

    @other_invoice = Invoice.create!(
      organization: @other_organization,
      customer: @other_customer,
      number: "INV-OTHER-ITEM-001",
      issue_date: Date.current,
      status: "draft",
      subtotal: 200.0,
      tax_amount: 40.0,
      total_amount: 240.0,
      amount_paid: 0.0,
      amount_due: 240.0
    )

    @service_item = ServiceItem.create!(
      organization: @organization,
      service_category: service_category,
      code: "TONTE-PEL",
      name: "Tonte de pelouse",
      unit: "m2",
      default_unit_price: 5.0
    )

    @other_service_item = ServiceItem.create!(
      organization: @other_organization,
      service_category: other_service_category,
      code: "OTHER-SERVICE",
      name: "Other Service",
      unit: "m2",
      default_unit_price: 5.0
    )

    @invoice_item = InvoiceItem.create!(
      invoice: @invoice,
      service_item: @service_item,
      description: "Tonte de pelouse",
      unit: "m2",
      quantity: 20,
      unit_price: 5.0,
      discount_percentage: 0,
      tax_rate: 20,
      subtotal: 100.0,
      tax_amount: 20.0,
      total_amount: 120.0,
      position: 1
    )

    @other_invoice_item = InvoiceItem.create!(
      invoice: @other_invoice,
      service_item: @other_service_item,
      description: "Other Service",
      unit: "m2",
      quantity: 10,
      unit_price: 10.0,
      discount_percentage: 0,
      tax_rate: 20,
      subtotal: 100.0,
      tax_amount: 20.0,
      total_amount: 120.0,
      position: 1
    )

    @manager_token = JwtService.encode(@manager)
    @owner_token = JwtService.encode(@owner)
    @member_token = JwtService.encode(@member)
    @other_manager_token = JwtService.encode(@other_manager)

  end

  test "index requires authentication" do
    get "/api/v1/invoice_items"

    assert_response :unauthorized
  end

  test "index returns invoice items from current organization" do
    get "/api/v1/invoice_items",
        headers: {
          "Authorization" => "Bearer #{@manager_token}"
        }

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal 1, body.length
    assert_equal @invoice_item.id, body.first["id"]
  end

  test "show returns invoice item from same organization" do
    get "/api/v1/invoice_items/#{@invoice_item.id}",
        headers: {
          "Authorization" => "Bearer #{@manager_token}"
        }

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal @invoice_item.id, body["id"]
  end

  test "show cannot access invoice item from another organization" do
    get "/api/v1/invoice_items/#{@other_invoice_item.id}",
        headers: {
          "Authorization" => "Bearer #{@manager_token}"
        }

    assert_response :not_found
  end

  test "manager can create invoice item" do
    assert_difference("InvoiceItem.count", 1) do
      post "/api/v1/invoice_items",
           params: {
             invoice_item: {
               invoice_id: @invoice.id,
               service_item_id: @service_item.id,
               description: "Taille de haie",
               unit: "ml",
               quantity: 10,
               unit_price: 15.0,
               discount_percentage: 0,
               tax_rate: 20,
               subtotal: 150.0,
               tax_amount: 30.0,
               total_amount: 180.0,
               position: 2
             }
           },
           headers: {
             "Authorization" => "Bearer #{@manager_token}"
           }
    end

    assert_response :created

    body = JSON.parse(response.body)

    assert_equal @invoice.id, body["invoice_id"]
    assert_equal @service_item.id, body["service_item_id"]
    assert_equal "Taille de haie", body["description"]
  end

  test "member cannot create invoice item" do
    assert_no_difference("InvoiceItem.count") do
      post "/api/v1/invoice_items",
           params: {
             invoice_item: {
               invoice_id: @invoice.id,
               description: "Unauthorized item",
               unit: "m2",
               quantity: 10,
               unit_price: 5.0,
               position: 2
             }
           },
           headers: {
             "Authorization" => "Bearer #{@member_token}"
           }
    end

    assert_response :forbidden
  end

  test "manager cannot create invoice item for invoice from another organization" do
    assert_no_difference("InvoiceItem.count") do
      post "/api/v1/invoice_items",
           params: {
             invoice_item: {
               invoice_id: @other_invoice.id,
               description: "Cross organization item",
               unit: "m2",
               quantity: 10,
               unit_price: 5.0,
               position: 2
             }
           },
           headers: {
             "Authorization" => "Bearer #{@manager_token}"
           }
    end

    assert_response :forbidden
  end

  test "manager cannot create invoice item with service item from another organization" do
    assert_no_difference("InvoiceItem.count") do
      post "/api/v1/invoice_items",
           params: {
             invoice_item: {
               invoice_id: @invoice.id,
               service_item_id: @other_service_item.id,
               description: "Cross organization service",
               unit: "m2",
               quantity: 10,
               unit_price: 5.0,
               position: 2
             }
           },
           headers: {
             "Authorization" => "Bearer #{@manager_token}"
           }
    end

    assert_response :forbidden
  end

  test "manager can update invoice item" do
    patch "/api/v1/invoice_items/#{@invoice_item.id}",
          params: {
            invoice_item: {
              description: "Updated description"
            }
          },
          headers: {
            "Authorization" => "Bearer #{@manager_token}"
          }

    assert_response :success

    assert_equal "Updated description", @invoice_item.reload.description
  end

  test "member cannot update invoice item" do
    patch "/api/v1/invoice_items/#{@invoice_item.id}",
          params: {
            invoice_item: {
              description: "Unauthorized update"
            }
          },
          headers: {
            "Authorization" => "Bearer #{@member_token}"
          }

    assert_response :forbidden

    assert_equal "Tonte de pelouse", @invoice_item.reload.description
  end

  test "manager cannot update invoice item from another organization" do
    patch "/api/v1/invoice_items/#{@other_invoice_item.id}",
          params: {
            invoice_item: {
              description: "Cross organization update"
            }
          },
          headers: {
            "Authorization" => "Bearer #{@manager_token}"
          }

    assert_response :not_found

    assert_equal "Other Service", @other_invoice_item.reload.description
  end

  test "manager cannot destroy invoice item" do
    assert_no_difference("InvoiceItem.count") do
      delete "/api/v1/invoice_items/#{@invoice_item.id}",
             headers: {
               "Authorization" => "Bearer #{@manager_token}"
             }
    end

    assert_response :forbidden
  end

  test "owner can destroy invoice item" do
    assert_difference("InvoiceItem.count", -1) do
      delete "/api/v1/invoice_items/#{@invoice_item.id}",
             headers: {
               "Authorization" => "Bearer #{@owner_token}"
             }
    end

    assert_response :no_content
  end

  test "validation errors return unprocessable entity" do
    post "/api/v1/invoice_items",
         params: {
           invoice_item: {
             invoice_id: @invoice.id,
             description: "",
             unit: "",
             quantity: 0,
             unit_price: -1,
             position: 2
           }
         },
         headers: {
           "Authorization" => "Bearer #{@manager_token}"
         }

    assert_response :unprocessable_entity

    body = JSON.parse(response.body)

    assert_equal "Unprocessable Entity", body["error"]
    assert body["messages"].any?
  end

  private

  def service_category
  @service_category ||= ServiceCategory.create!(
    organization: @organization,
    name: "Entretien",
    code: "ENT"
  )
end

def other_service_category
  @other_service_category ||= ServiceCategory.create!(
    organization: @other_organization,
    name: "Other Category",
    code: "OTHER"
  )
end

  def create_user(organization:, email:, role:)
    User.create!(
      organization: organization,
      email: email,
      first_name: "Test",
      last_name: "User",
      password: "password",
      password_confirmation: "password",
      role: role
    )
  end
end