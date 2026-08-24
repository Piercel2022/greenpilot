require "test_helper"

class Api::V1::InvoicesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organization = Organization.create!(
      name: "GreenPilot Invoices Test",
      slug: "greenpilot-invoices-test"
    )

    @other_organization = Organization.create!(
      name: "Other Organization",
      slug: "other-organization-invoices-test"
    )

    @manager = create_user(
      organization: @organization,
      email: "manager-invoices@example.com",
      role: "manager"
    )

    @owner = create_user(
      organization: @organization,
      email: "owner-invoices@example.com",
      role: "owner"
    )

    @accountant = create_user(
      organization: @organization,
      email: "accountant-invoices@example.com",
      role: "accountant"
    )

    @member = create_user(
      organization: @organization,
      email: "member-invoices@example.com",
      role: "member"
    )

    @other_manager = create_user(
      organization: @other_organization,
      email: "other-manager-invoices@example.com",
      role: "manager"
    )

    @customer = Customer.create!(
      organization: @organization,
      customer_type: "individual",
      first_name: "John",
      last_name: "Customer",
      email: "john-invoices@example.com"
    )

    @other_customer = Customer.create!(
      organization: @other_organization,
      customer_type: "individual",
      first_name: "Other",
      last_name: "Customer",
      email: "other-customer-invoices@example.com"
    )

    @site = Site.create!(
      organization: @organization,
      customer: @customer,
      name: "Invoice Site"
    )

    @other_site = Site.create!(
      organization: @other_organization,
      customer: @other_customer,
      name: "Other Invoice Site"
    )

    @job = Job.create!(
      organization: @organization,
      customer: @customer,
      site: @site,
      title: "Invoice Job",
      job_type: "maintenance",
      status: "planned",
      priority: "normal",
      scheduled_date: Date.current
    )

    @other_job = Job.create!(
      organization: @other_organization,
      customer: @other_customer,
      site: @other_site,
      title: "Other Invoice Job",
      job_type: "maintenance",
      status: "planned",
      priority: "normal",
      scheduled_date: Date.current
    )

    @invoice = Invoice.create!(
      organization: @organization,
      customer: @customer,
      site: @site,
      job: @job,
      number: "INV-TEST-001",
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
      site: @other_site,
      job: @other_job,
      number: "INV-OTHER-001",
      issue_date: Date.current,
      status: "draft",
      subtotal: 200.0,
      tax_amount: 40.0,
      total_amount: 240.0,
      amount_paid: 0.0,
      amount_due: 240.0
    )

    @manager_token = JwtService.encode(@manager)
    @owner_token = JwtService.encode(@owner)
    @accountant_token = JwtService.encode(@accountant)
    @member_token = JwtService.encode(@member)
    @other_manager_token = JwtService.encode(@other_manager)
  end

  test "index requires authentication" do
    get "/api/v1/invoices"

    assert_response :unauthorized
  end

  test "index returns invoices from the current organization" do
    get "/api/v1/invoices",
        headers: {
          "Authorization" => "Bearer #{@manager_token}"
        }

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal 1, body.length
    assert_equal @invoice.id, body.first["id"]
  end

  test "show returns an invoice from the same organization" do
    get "/api/v1/invoices/#{@invoice.id}",
        headers: {
          "Authorization" => "Bearer #{@manager_token}"
        }

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal @invoice.id, body["id"]
  end

  test "show cannot access an invoice from another organization" do
    get "/api/v1/invoices/#{@other_invoice.id}",
        headers: {
          "Authorization" => "Bearer #{@manager_token}"
        }

    assert_response :not_found
  end

  test "manager can create an invoice" do
    assert_difference("Invoice.count", 1) do
      post "/api/v1/invoices",
           params: {
             invoice: {
               customer_id: @customer.id,
               site_id: @site.id,
               job_id: @job.id,
               number: "INV-NEW-001",
               issue_date: Date.current,
               status: "draft",
               subtotal: 500.0,
               tax_amount: 100.0,
               total_amount: 600.0,
               amount_paid: 0.0,
               amount_due: 600.0
             }
           },
           headers: {
             "Authorization" => "Bearer #{@manager_token}"
           }
    end

    assert_response :created

    body = JSON.parse(response.body)

    assert_equal "INV-NEW-001", body["number"]
    assert_equal @organization.id, body["organization_id"]
    assert_equal @customer.id, body["customer_id"]
    assert_equal @job.id, body["job_id"]
  end

  test "member cannot create an invoice" do
    assert_no_difference("Invoice.count") do
      post "/api/v1/invoices",
           params: {
             invoice: {
               customer_id: @customer.id,
               number: "INV-UNAUTHORIZED-001",
               issue_date: Date.current
             }
           },
           headers: {
             "Authorization" => "Bearer #{@member_token}"
           }
    end

    assert_response :forbidden
  end

  test "accountant can update an invoice" do
    patch "/api/v1/invoices/#{@invoice.id}",
          params: {
            invoice: {
              status: "sent"
            }
          },
          headers: {
            "Authorization" => "Bearer #{@accountant_token}"
          }

    assert_response :success

    assert_equal "sent", @invoice.reload.status
  end

  test "manager can update an invoice" do
    patch "/api/v1/invoices/#{@invoice.id}",
          params: {
            invoice: {
              notes: "Updated invoice"
            }
          },
          headers: {
            "Authorization" => "Bearer #{@manager_token}"
          }

    assert_response :success

    assert_equal "Updated invoice", @invoice.reload.notes
  end

  test "member cannot update an invoice" do
    patch "/api/v1/invoices/#{@invoice.id}",
          params: {
            invoice: {
              notes: "Unauthorized update"
            }
          },
          headers: {
            "Authorization" => "Bearer #{@member_token}"
          }

    assert_response :forbidden

    assert_nil @invoice.reload.notes
  end

  test "manager cannot destroy an invoice" do
    assert_no_difference("Invoice.count") do
      delete "/api/v1/invoices/#{@invoice.id}",
             headers: {
               "Authorization" => "Bearer #{@manager_token}"
             }
    end

    assert_response :forbidden
  end

  test "owner can destroy an invoice" do
    assert_difference("Invoice.count", -1) do
      delete "/api/v1/invoices/#{@invoice.id}",
             headers: {
               "Authorization" => "Bearer #{@owner_token}"
             }
    end

    assert_response :no_content
  end

  test "cannot create an invoice with customer from another organization" do
    assert_no_difference("Invoice.count") do
      post "/api/v1/invoices",
           params: {
             invoice: {
               customer_id: @other_customer.id,
               number: "INV-CROSS-CUSTOMER",
               issue_date: Date.current
             }
           },
           headers: {
             "Authorization" => "Bearer #{@manager_token}"
           }
    end

    assert_response :forbidden
  end

  test "cannot create an invoice with job from another organization" do
    assert_no_difference("Invoice.count") do
      post "/api/v1/invoices",
           params: {
             invoice: {
               customer_id: @customer.id,
               job_id: @other_job.id,
               number: "INV-CROSS-JOB",
               issue_date: Date.current
             }
           },
           headers: {
             "Authorization" => "Bearer #{@manager_token}"
           }
    end

    assert_response :forbidden
  end

  test "cannot create an invoice with site from another organization" do
    assert_no_difference("Invoice.count") do
      post "/api/v1/invoices",
           params: {
             invoice: {
               customer_id: @customer.id,
               site_id: @other_site.id,
               number: "INV-CROSS-SITE",
               issue_date: Date.current
             }
           },
           headers: {
             "Authorization" => "Bearer #{@manager_token}"
           }
    end

    assert_response :forbidden
  end

  test "manager cannot update an invoice from another organization" do
    patch "/api/v1/invoices/#{@other_invoice.id}",
          params: {
            invoice: {
              notes: "Unauthorized cross organization update"
            }
          },
          headers: {
            "Authorization" => "Bearer #{@manager_token}"
          }

    assert_response :not_found

    assert_nil @other_invoice.reload.notes
  end

end