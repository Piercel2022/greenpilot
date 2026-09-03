
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

    @owner = User.create!(
      organization: @organization,
      email: "owner-quotes@example.com",
      first_name: "Quote",
      last_name: "Owner",
      role: "owner",
      password: "password123",
      password_confirmation: "password123"
    )

    @admin = User.create!(
      organization: @organization,
      email: "admin-quotes@example.com",
      first_name: "Quote",
      last_name: "Admin",
      role: "admin",
      password: "password123",
      password_confirmation: "password123"
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

    @other_manager = User.create!(
      organization: @other_organization,
      email: "manager-other-quotes@example.com",
      first_name: "Other",
      last_name: "Quote Manager",
      role: "manager",
      password: "password123",
      password_confirmation: "password123"
    )

    @other_manager_token = JwtService.encode(@other_manager)

    @accountant = User.create!(
      organization: @organization,
      email: "accountant-quotes@example.com",
      first_name: "Quote",
      last_name: "Accountant",
      role: "accountant",
      password: "password123",
      password_confirmation: "password123"
    )

    @field_worker = User.create!(
      organization: @organization,
      email: "field-worker-quotes@example.com",
      first_name: "Quote",
      last_name: "Field Worker",
      role: "field_worker",
      password: "password123",
      password_confirmation: "password123"
    )

    @member = User.create!(
      organization: @organization,
      email: "member-quotes@example.com",
      first_name: "Quote",
      last_name: "Member",
      role: "member",
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

    @second_customer = Customer.create!(
      organization: @organization,
      customer_type: "individual",
      first_name: "Jane",
      last_name: "Customer",
      email: "jane-quotes@example.com"
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

    @second_site = Site.create!(
      organization: @organization,
      customer: @second_customer,
      name: "Second site",
      address_line1: "15 rue des Fleurs",
      city: "Strasbourg",
      postal_code: "67100",
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

    @owner_token = JwtService.encode(@owner)
    @admin_token = JwtService.encode(@admin)
    @manager_token = JwtService.encode(@manager)
    @accountant_token = JwtService.encode(@accountant)
    @field_worker_token = JwtService.encode(@field_worker)
    @member_token = JwtService.encode(@member)
  end

  test "index requires authentication" do
    get "/api/v1/quotes"

    assert_response :unauthorized
  end

  test "index returns quotes from authenticated user's organization" do
    get "/api/v1/quotes",
        headers: {
          "Authorization" => "Bearer #{@manager_token}"
        }

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal 1, body.length
    assert_equal @quote.id, body.first["id"]
    assert_equal @organization.id, body.first["organization_id"]
  end

  test "index does not expose quotes from another organization" do
    get "/api/v1/quotes",
        headers: {
          "Authorization" => "Bearer #{@manager_token}"
        }

    assert_response :success

    body = JSON.parse(response.body)

    assert body.none? { |quote| quote["id"] == @other_quote.id }
    assert body.none? { |quote| quote["organization_id"] == @other_organization.id }
  end

  test "show returns quote from same organization" do
    get "/api/v1/quotes/#{@quote.id}",
        headers: {
          "Authorization" => "Bearer #{@manager_token}"
        }

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal @quote.id, body["id"]
    assert_equal "DEV-2026-0001", body["number"]
    assert_equal "Entretien annuel", body["title"]
    assert_equal @customer.id, body["customer_id"]
    assert_equal @site.id, body["site_id"]
    assert_equal @organization.id, body["organization_id"]
  end

  test "show does not expose quote from another organization" do
    get "/api/v1/quotes/#{@other_quote.id}",
        headers: {
          "Authorization" => "Bearer #{@manager_token}"
        }

    assert_response :not_found

    body = JSON.parse(response.body)

    assert_equal "Not Found", body["error"]
  end

  test "show returns not found for a nonexistent quote" do
    get "/api/v1/quotes/00000000-0000-0000-0000-000000000000",
        headers: {
          "Authorization" => "Bearer #{@manager_token}"
        }

    assert_response :not_found

    body = JSON.parse(response.body)

    assert_equal "Not Found", body["error"]
  end

  test "owner can create quote" do
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
             "Authorization" => "Bearer #{@owner_token}"
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

  test "admin can create quote" do
    assert_difference("Quote.count", 1) do
      post "/api/v1/quotes",
           params: {
             quote: {
               customer_id: @customer.id,
               site_id: @site.id,
               number: "DEV-2026-0003",
               title: "Devis administrateur",
               issue_date: Date.current,
               status: "draft"
             }
           },
           headers: {
             "Authorization" => "Bearer #{@admin_token}"
           }
    end

    assert_response :created
  end

  test "manager can create quote" do
    assert_difference("Quote.count", 1) do
      post "/api/v1/quotes",
           params: {
             quote: {
               customer_id: @customer.id,
               site_id: @site.id,
               number: "DEV-2026-0004",
               title: "Devis manager",
               issue_date: Date.current,
               status: "draft"
             }
           },
           headers: {
             "Authorization" => "Bearer #{@manager_token}"
           }
    end

    assert_response :created
  end

  test "accountant cannot create quote" do
    assert_no_difference("Quote.count") do
      post "/api/v1/quotes",
           params: {
             quote: {
               customer_id: @customer.id,
               site_id: @site.id,
               number: "DEV-ACCOUNTANT",
               title: "Unauthorized Accountant Quote",
               issue_date: Date.current
             }
           },
           headers: {
             "Authorization" => "Bearer #{@accountant_token}"
           }
    end

    assert_not Quote.exists?(number: "DEV-ACCOUNTANT")
  end

  test "field worker cannot create quote" do
    assert_no_difference("Quote.count") do
      post "/api/v1/quotes",
           params: {
             quote: {
               customer_id: @customer.id,
               site_id: @site.id,
               number: "DEV-FIELD",
               title: "Unauthorized Field Worker Quote",
               issue_date: Date.current
             }
           },
           headers: {
             "Authorization" => "Bearer #{@field_worker_token}"
           }
    end

    assert_not Quote.exists?(number: "DEV-FIELD")
  end

  test "member cannot create quote" do
    assert_no_difference("Quote.count") do
      post "/api/v1/quotes",
           params: {
             quote: {
               customer_id: @customer.id,
               site_id: @site.id,
               number: "DEV-MEMBER",
               title: "Unauthorized Member Quote",
               issue_date: Date.current
             }
           },
           headers: {
             "Authorization" => "Bearer #{@member_token}"
           }
    end

    assert_not Quote.exists?(number: "DEV-MEMBER")
  end

  test "create always assigns the current user's organization" do
    assert_difference("Quote.count", 1) do
      post "/api/v1/quotes",
           params: {
             quote: {
               organization_id: @other_organization.id,
               customer_id: @customer.id,
               site_id: @site.id,
               number: "DEV-TENANT",
               title: "Tenant Isolation Test",
               issue_date: Date.current
             }
           },
           headers: {
             "Authorization" => "Bearer #{@manager_token}"
           }
    end

    assert_response :created

    quote = Quote.order(created_at: :desc).first

    assert_equal @organization.id, quote.organization_id
    assert_not_equal @other_organization.id, quote.organization_id
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
             "Authorization" => "Bearer #{@manager_token}"
           }
    end

    assert_response :unprocessable_entity

    body = JSON.parse(response.body)

    assert_equal "Unprocessable Entity", body["error"]
    assert_includes body["messages"],
                    "Site must belong to the selected customer"
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
             "Authorization" => "Bearer #{@manager_token}"
           }
    end

    assert_response :unprocessable_entity

    body = JSON.parse(response.body)

    assert_equal "Unprocessable Entity", body["error"]
    assert_includes body["messages"],
                    "Site must belong to the same organization"
    assert_includes body["messages"],
                    "Site must belong to the selected customer"
  end

  test "manager cannot create quote with site from another customer" do
    assert_no_difference("Quote.count") do
      post "/api/v1/quotes",
           params: {
             quote: {
               customer_id: @customer.id,
               site_id: @second_site.id,
               number: "DEV-HACK-CROSS-CUSTOMER",
               title: "Invalid Customer Site Quote",
               issue_date: Date.current
             }
           },
           headers: {
             "Authorization" => "Bearer #{@manager_token}"
           }
    end

    assert_response :unprocessable_entity

    body = JSON.parse(response.body)

    assert_equal "Unprocessable Entity", body["error"]
    assert_includes body["messages"],
                    "Site must belong to the selected customer"
  end

  test "create returns unprocessable entity for invalid quote" do
    assert_no_difference("Quote.count") do
      post "/api/v1/quotes",
           params: {
             quote: {
               customer_id: @customer.id,
               site_id: @site.id,
               number: nil,
               title: nil,
               issue_date: nil
             }
           },
           headers: {
             "Authorization" => "Bearer #{@manager_token}"
           }
    end

    assert_response :unprocessable_entity

    body = JSON.parse(response.body)

    assert_equal "Unprocessable Entity", body["error"]
    assert body["messages"].any?
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
             "Authorization" => "Bearer #{@manager_token}"
           }
    end

    assert_response :unprocessable_entity

    body = JSON.parse(response.body)

    assert body["messages"].any? { |message| message.include?("Number") }
  end

  test "same quote number is allowed in another organization" do
  assert_difference("Quote.count", 1) do
    post "/api/v1/quotes",
         params: {
           quote: {
             customer_id: @other_customer.id,
             site_id: @other_site.id,
             number: "DEV-2026-0001",
             title: "Other Organization Quote",
             issue_date: Date.current
           }
         },
         headers: {
           "Authorization" => "Bearer #{@other_manager_token}"
         }
  end

  assert_response :created

  body = JSON.parse(response.body)

  assert_equal "DEV-2026-0001", body["number"]
  assert_equal "Other Organization Quote", body["title"]
  assert_equal @other_customer.id, body["customer_id"]
  assert_equal @other_site.id, body["site_id"]
  assert_equal @other_organization.id, body["organization_id"]
end

  test "owner can update quote" do
    patch "/api/v1/quotes/#{@quote.id}",
          params: {
            quote: {
              title: "Entretien annuel Owner",
              description: "Description Owner",
              valid_until: Date.current + 45.days
            }
          },
          headers: {
            "Authorization" => "Bearer #{@owner_token}"
          }

    assert_response :success

    @quote.reload

    assert_equal "Entretien annuel Owner", @quote.title
    assert_equal "Description Owner", @quote.description
    assert_equal Date.current + 45.days, @quote.valid_until
  end

  test "admin can update quote" do
    patch "/api/v1/quotes/#{@quote.id}",
          params: {
            quote: {
              title: "Entretien annuel Admin"
            }
          },
          headers: {
            "Authorization" => "Bearer #{@admin_token}"
          }

    assert_response :success

    assert_equal "Entretien annuel Admin", @quote.reload.title
  end

  test "manager can update quote" do
    patch "/api/v1/quotes/#{@quote.id}",
          params: {
            quote: {
              title: "Entretien annuel Manager"
            }
          },
          headers: {
            "Authorization" => "Bearer #{@manager_token}"
          }

    assert_response :success

    assert_equal "Entretien annuel Manager", @quote.reload.title
  end

  test "accountant cannot update quote" do
    patch "/api/v1/quotes/#{@quote.id}",
          params: {
            quote: {
              title: "Unauthorized Accountant Update"
            }
          },
          headers: {
            "Authorization" => "Bearer #{@accountant_token}"
          }

    assert_equal "Entretien annuel", @quote.reload.title
  end

  test "field worker cannot update quote" do
    patch "/api/v1/quotes/#{@quote.id}",
          params: {
            quote: {
              title: "Unauthorized Field Worker Update"
            }
          },
          headers: {
            "Authorization" => "Bearer #{@field_worker_token}"
          }

    assert_equal "Entretien annuel", @quote.reload.title
  end

  test "member cannot update quote" do
    patch "/api/v1/quotes/#{@quote.id}",
          params: {
            quote: {
              title: "Unauthorized Member Update"
            }
          },
          headers: {
            "Authorization" => "Bearer #{@member_token}"
          }

    assert_equal "Entretien annuel", @quote.reload.title
  end

  test "manager cannot update quote from another organization" do
    patch "/api/v1/quotes/#{@other_quote.id}",
          params: {
            quote: {
              title: "Unauthorized update"
            }
          },
          headers: {
            "Authorization" => "Bearer #{@manager_token}"
          }

    assert_response :not_found

    assert_equal "Other Quote", @other_quote.reload.title
  end

  test "manager cannot update quote to customer from another organization" do
    patch "/api/v1/quotes/#{@quote.id}",
          params: {
            quote: {
              customer_id: @other_customer.id
            }
          },
          headers: {
            "Authorization" => "Bearer #{@manager_token}"
          }

    assert_response :unprocessable_entity

    assert_equal @customer.id, @quote.reload.customer_id
  end

  test "manager cannot update quote to site from another organization" do
    patch "/api/v1/quotes/#{@quote.id}",
          params: {
            quote: {
              site_id: @other_site.id
            }
          },
          headers: {
            "Authorization" => "Bearer #{@manager_token}"
          }

    assert_response :unprocessable_entity

    assert_equal @site.id, @quote.reload.site_id
  end

  test "manager cannot update quote to site from another customer" do
    patch "/api/v1/quotes/#{@quote.id}",
          params: {
            quote: {
              site_id: @second_site.id
            }
          },
          headers: {
            "Authorization" => "Bearer #{@manager_token}"
          }

    assert_response :unprocessable_entity

    assert_equal @site.id, @quote.reload.site_id
  end

  test "update returns unprocessable entity for invalid quote" do
    patch "/api/v1/quotes/#{@quote.id}",
          params: {
            quote: {
              number: nil,
              title: nil,
              issue_date: nil
            }
          },
          headers: {
            "Authorization" => "Bearer #{@manager_token}"
          }

    assert_response :unprocessable_entity

    body = JSON.parse(response.body)

    assert_equal "Unprocessable Entity", body["error"]
    assert body["messages"].any?

    @quote.reload

    assert_equal "DEV-2026-0001", @quote.number
    assert_equal "Entretien annuel", @quote.title
  end

  test "update returns not found for a nonexistent quote" do
    patch "/api/v1/quotes/00000000-0000-0000-0000-000000000000",
          params: {
            quote: {
              title: "Updated"
            }
          },
          headers: {
            "Authorization" => "Bearer #{@manager_token}"
          }

    assert_response :not_found
  end

  test "owner can destroy quote" do
    assert_difference("Quote.count", -1) do
      delete "/api/v1/quotes/#{@quote.id}",
             headers: {
               "Authorization" => "Bearer #{@owner_token}"
             }
    end

    assert_response :no_content
  end

  test "admin can destroy quote" do
    quote = Quote.create!(
      organization: @organization,
      customer: @customer,
      site: @site,
      number: "DEV-DELETE-ADMIN",
      title: "Admin Delete",
      issue_date: Date.current,
      status: "draft"
    )

    assert_difference("Quote.count", -1) do
      delete "/api/v1/quotes/#{quote.id}",
             headers: {
               "Authorization" => "Bearer #{@admin_token}"
             }
    end

    assert_response :no_content
  end

  test "manager cannot destroy quote" do
    delete "/api/v1/quotes/#{@quote.id}",
           headers: {
             "Authorization" => "Bearer #{@manager_token}"
           }

    assert Quote.exists?(@quote.id)
  end

  test "accountant cannot destroy quote" do
    delete "/api/v1/quotes/#{@quote.id}",
           headers: {
             "Authorization" => "Bearer #{@accountant_token}"
           }

    assert Quote.exists?(@quote.id)
  end

  test "field worker cannot destroy quote" do
    delete "/api/v1/quotes/#{@quote.id}",
           headers: {
             "Authorization" => "Bearer #{@field_worker_token}"
           }

    assert Quote.exists?(@quote.id)
  end

  test "member cannot destroy quote" do
    delete "/api/v1/quotes/#{@quote.id}",
           headers: {
             "Authorization" => "Bearer #{@member_token}"
           }

    assert Quote.exists?(@quote.id)
  end

  test "owner cannot destroy quote from another organization" do
    assert_no_difference("Quote.count") do
      delete "/api/v1/quotes/#{@other_quote.id}",
             headers: {
               "Authorization" => "Bearer #{@owner_token}"
             }
    end

    assert_response :not_found

    assert Quote.exists?(@other_quote.id)
  end

  test "destroy returns not found for a nonexistent quote" do
    delete "/api/v1/quotes/00000000-0000-0000-0000-000000000000",
           headers: {
             "Authorization" => "Bearer #{@owner_token}"
           }

    assert_response :not_found
  end
test "POST /quotes cannot inject organization_id from another organization" do
  assert_difference("Quote.count", 1) do
    post "/api/v1/quotes",
         params: {
           quote: {
             organization_id: @other_organization.id,
             customer_id: @customer.id,
             site_id: @site.id,
             number: "DEV-ATTACK-ORG",
             title: "Malicious quote",
             issue_date: Date.current
           }
         },
         headers: {
           "Authorization" => "Bearer #{@manager_token}"
         }
  end

  assert_response :created

  body = JSON.parse(response.body)

  created_quote = Quote.find(body["id"])

  assert_equal @organization.id, created_quote.organization_id
  assert_not_equal @other_organization.id, created_quote.organization_id

  assert_equal @customer.id, created_quote.customer_id
  assert_equal @site.id, created_quote.site_id
end
  
end