require "test_helper"

class Api::V1::CustomersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organization = Organization.create!(
      name: "GreenPilot API Test",
      slug: "greenpilot-api-test"
    )

    @other_organization = Organization.create!(
      name: "Other Organization",
      slug: "other-organization-customers-test"
    )

    @owner = User.create!(
      organization: @organization,
      email: "owner-api@example.com",
      first_name: "API",
      last_name: "Owner",
      role: "owner",
      password: "password123",
      password_confirmation: "password123"
    )

    @admin = User.create!(
      organization: @organization,
      email: "admin-api@example.com",
      first_name: "API",
      last_name: "Admin",
      role: "admin",
      password: "password123",
      password_confirmation: "password123"
    )

    @manager = User.create!(
      organization: @organization,
      email: "manager-api@example.com",
      first_name: "API",
      last_name: "Manager",
      role: "manager",
      password: "password123",
      password_confirmation: "password123"
    )

    @accountant = User.create!(
      organization: @organization,
      email: "accountant-api@example.com",
      first_name: "API",
      last_name: "Accountant",
      role: "accountant",
      password: "password123",
      password_confirmation: "password123"
    )

    @field_worker = User.create!(
      organization: @organization,
      email: "field-worker-api@example.com",
      first_name: "API",
      last_name: "Field Worker",
      role: "field_worker",
      password: "password123",
      password_confirmation: "password123"
    )

    @member = User.create!(
      organization: @organization,
      email: "member-api@example.com",
      first_name: "API",
      last_name: "Member",
      role: "member",
      password: "password123",
      password_confirmation: "password123"
    )

    @other_manager = User.create!(
      organization: @other_organization,
      email: "other-manager-api@example.com",
      first_name: "Other",
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
      email: "john@example.com"
    )

    @other_customer = Customer.create!(
      organization: @other_organization,
      customer_type: "individual",
      first_name: "Other",
      last_name: "Customer",
      email: "other@example.com"
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
    get "/api/v1/customers"

    assert_response :unauthorized
  end

  test "index returns customers for authenticated user organization" do
    get "/api/v1/customers",
        headers: {
          "Authorization" => "Bearer #{@manager_token}"
        }

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal 1, body.length
    assert_equal @customer.id, body.first["id"]
  end

  test "index does not expose customers from another organization" do
    get "/api/v1/customers",
        headers: {
          "Authorization" => "Bearer #{@manager_token}"
        }

    assert_response :success

    body = JSON.parse(response.body)

    assert body.none? { |customer| customer["id"] == @other_customer.id }
  end

  test "show returns customer from same organization" do
    get "/api/v1/customers/#{@customer.id}",
        headers: {
          "Authorization" => "Bearer #{@manager_token}"
        }

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal @customer.id, body["id"]
    assert_equal @organization.id, body["organization_id"]
  end

  test "show does not expose customer from another organization" do
    get "/api/v1/customers/#{@other_customer.id}",
        headers: {
          "Authorization" => "Bearer #{@manager_token}"
        }

    assert_response :not_found

    body = JSON.parse(response.body)

    assert_equal "Not Found", body["error"]
  end

  test "show returns not found for a nonexistent customer" do
    get "/api/v1/customers/00000000-0000-0000-0000-000000000000",
        headers: {
          "Authorization" => "Bearer #{@manager_token}"
        }

    assert_response :not_found
  end

  test "owner can create customer" do
    assert_difference("Customer.count", 1) do
      post "/api/v1/customers",
           params: {
             customer: {
               customer_type: "individual",
               first_name: "Alice",
               last_name: "Owner",
               email: "alice-owner@example.com"
             }
           },
           headers: {
             "Authorization" => "Bearer #{@owner_token}"
           }
    end

    assert_response :created

    body = JSON.parse(response.body)

    assert_equal "Alice", body["first_name"]
    assert_equal @organization.id, body["organization_id"]
  end

  test "admin can create customer" do
    assert_difference("Customer.count", 1) do
      post "/api/v1/customers",
           params: {
             customer: {
               customer_type: "individual",
               first_name: "Alice",
               last_name: "Admin",
               email: "alice-admin@example.com"
             }
           },
           headers: {
             "Authorization" => "Bearer #{@admin_token}"
           }
    end

    assert_response :created
  end

  test "manager can create customer" do
    assert_difference("Customer.count", 1) do
      post "/api/v1/customers",
           params: {
             customer: {
               customer_type: "individual",
               first_name: "Alice",
               last_name: "Martin",
               email: "alice@example.com"
             }
           },
           headers: {
             "Authorization" => "Bearer #{@manager_token}"
           }
    end

    assert_response :created

    body = JSON.parse(response.body)

    assert_equal "Alice", body["first_name"]
    assert_equal @organization.id, body["organization_id"]
  end

  test "accountant cannot create customer" do
    assert_no_difference("Customer.count") do
      post "/api/v1/customers",
           params: {
             customer: {
               customer_type: "individual",
               first_name: "Unauthorized",
               last_name: "Accountant"
             }
           },
           headers: {
             "Authorization" => "Bearer #{@accountant_token}"
           }
    end

    assert_response :forbidden
  end

  test "field worker cannot create customer" do
    assert_no_difference("Customer.count") do
      post "/api/v1/customers",
           params: {
             customer: {
               customer_type: "individual",
               first_name: "Unauthorized",
               last_name: "Worker"
             }
           },
           headers: {
             "Authorization" => "Bearer #{@field_worker_token}"
           }
    end

    assert_response :forbidden
  end

  test "member cannot create customer" do
    assert_no_difference("Customer.count") do
      post "/api/v1/customers",
           params: {
             customer: {
               customer_type: "individual",
               first_name: "Unauthorized",
               last_name: "Member"
             }
           },
           headers: {
             "Authorization" => "Bearer #{@member_token}"
           }
    end

    assert_response :forbidden
  end

  test "create returns unprocessable entity for invalid customer" do
    assert_no_difference("Customer.count") do
      post "/api/v1/customers",
           params: {
             customer: {
               customer_type: "invalid"
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

  test "create always assigns the current user's organization" do
    assert_difference("Customer.count", 1) do
      post "/api/v1/customers",
           params: {
             customer: {
               organization_id: @other_organization.id,
               customer_type: "individual",
               first_name: "Tenant",
               last_name: "Test"
             }
           },
           headers: {
             "Authorization" => "Bearer #{@manager_token}"
           }
    end

    assert_response :created

    customer = Customer.order(created_at: :desc).first

    assert_equal @organization.id, customer.organization_id
  end

  test "owner can update customer from same organization" do
    patch "/api/v1/customers/#{@customer.id}",
          params: {
            customer: {
              first_name: "Updated Owner"
            }
          },
          headers: {
            "Authorization" => "Bearer #{@owner_token}"
          }

    assert_response :success

    assert_equal "Updated Owner", @customer.reload.first_name
  end

  test "admin can update customer from same organization" do
    patch "/api/v1/customers/#{@customer.id}",
          params: {
            customer: {
              first_name: "Updated Admin"
            }
          },
          headers: {
            "Authorization" => "Bearer #{@admin_token}"
          }

    assert_response :success

    assert_equal "Updated Admin", @customer.reload.first_name
  end

  test "manager can update customer from same organization" do
    patch "/api/v1/customers/#{@customer.id}",
          params: {
            customer: {
              first_name: "Updated Manager"
            }
          },
          headers: {
            "Authorization" => "Bearer #{@manager_token}"
          }

    assert_response :success

    assert_equal "Updated Manager", @customer.reload.first_name
  end

  test "accountant cannot update customer" do
    patch "/api/v1/customers/#{@customer.id}",
          params: {
            customer: {
              first_name: "Unauthorized"
            }
          },
          headers: {
            "Authorization" => "Bearer #{@accountant_token}"
          }

    assert_response :forbidden

    assert_equal "John", @customer.reload.first_name
  end

  test "field worker cannot update customer" do
    patch "/api/v1/customers/#{@customer.id}",
          params: {
            customer: {
              first_name: "Unauthorized"
            }
          },
          headers: {
            "Authorization" => "Bearer #{@field_worker_token}"
          }

    assert_response :forbidden

    assert_equal "John", @customer.reload.first_name
  end

  test "member cannot update customer" do
    patch "/api/v1/customers/#{@customer.id}",
          params: {
            customer: {
              first_name: "Unauthorized"
            }
          },
          headers: {
            "Authorization" => "Bearer #{@member_token}"
          }

    assert_response :forbidden

    assert_equal "John", @customer.reload.first_name
  end

  test "manager cannot update customer from another organization" do
    patch "/api/v1/customers/#{@other_customer.id}",
          params: {
            customer: {
              first_name: "Unauthorized"
            }
          },
          headers: {
            "Authorization" => "Bearer #{@manager_token}"
          }

    assert_response :not_found

    assert_equal "Other", @other_customer.reload.first_name
  end

  test "update returns unprocessable entity for invalid customer" do
    patch "/api/v1/customers/#{@customer.id}",
          params: {
            customer: {
              customer_type: "invalid"
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

  test "update returns not found for a nonexistent customer" do
    patch "/api/v1/customers/00000000-0000-0000-0000-000000000000",
          params: {
            customer: {
              first_name: "Updated"
            }
          },
          headers: {
            "Authorization" => "Bearer #{@manager_token}"
          }

    assert_response :not_found
  end

  test "owner can destroy customer" do
    assert_difference("Customer.count", -1) do
      delete "/api/v1/customers/#{@customer.id}",
             headers: {
               "Authorization" => "Bearer #{@owner_token}"
             }
    end

    assert_response :no_content
  end

  test "admin can destroy customer" do
    customer = Customer.create!(
      organization: @organization,
      customer_type: "individual",
      first_name: "Admin",
      last_name: "Delete",
      email: "admin-delete@example.com"
    )

    assert_difference("Customer.count", -1) do
      delete "/api/v1/customers/#{customer.id}",
             headers: {
               "Authorization" => "Bearer #{@admin_token}"
             }
    end

    assert_response :no_content
  end

  test "manager cannot destroy customer" do
    assert_no_difference("Customer.count") do
      delete "/api/v1/customers/#{@customer.id}",
             headers: {
               "Authorization" => "Bearer #{@manager_token}"
             }
    end

    assert_response :forbidden
  end

  test "accountant cannot destroy customer" do
    assert_no_difference("Customer.count") do
      delete "/api/v1/customers/#{@customer.id}",
             headers: {
               "Authorization" => "Bearer #{@accountant_token}"
             }
    end

    assert_response :forbidden
  end

  test "field worker cannot destroy customer" do
    assert_no_difference("Customer.count") do
      delete "/api/v1/customers/#{@customer.id}",
             headers: {
               "Authorization" => "Bearer #{@field_worker_token}"
             }
    end

    assert_response :forbidden
  end

  test "member cannot destroy customer" do
    assert_no_difference("Customer.count") do
      delete "/api/v1/customers/#{@customer.id}",
             headers: {
               "Authorization" => "Bearer #{@member_token}"
             }
    end

    assert_response :forbidden
  end

  test "owner cannot destroy customer from another organization" do
    assert_no_difference("Customer.count") do
      delete "/api/v1/customers/#{@other_customer.id}",
             headers: {
               "Authorization" => "Bearer #{@owner_token}"
             }
    end

    assert_response :not_found

    assert Customer.exists?(@other_customer.id)
  end

  test "destroy returns not found for a nonexistent customer" do
    delete "/api/v1/customers/00000000-0000-0000-0000-000000000000",
           headers: {
             "Authorization" => "Bearer #{@owner_token}"
           }

    assert_response :not_found
  end
end