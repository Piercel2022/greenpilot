require "test_helper"

class Api::V1::ServiceCategoriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organization = Organization.create!(
      name: "GreenPilot Service Categories Test",
      slug: "greenpilot-service-categories-test"
    )

    @other_organization = Organization.create!(
      name: "Other Service Categories Organization",
      slug: "other-service-categories-org"
    )

    @owner = User.create!(
      organization: @organization,
      email: "owner-service-categories@example.com",
      first_name: "Service",
      last_name: "Owner",
      role: "owner",
      password: "password123",
      password_confirmation: "password123"
    )

    @admin = User.create!(
      organization: @organization,
      email: "admin-service-categories@example.com",
      first_name: "Service",
      last_name: "Admin",
      role: "admin",
      password: "password123",
      password_confirmation: "password123"
    )

    @manager = User.create!(
      organization: @organization,
      email: "manager-service-categories@example.com",
      first_name: "Service",
      last_name: "Manager",
      role: "manager",
      password: "password123",
      password_confirmation: "password123"
    )

    @accountant = User.create!(
      organization: @organization,
      email: "accountant-service-categories@example.com",
      first_name: "Service",
      last_name: "Accountant",
      role: "accountant",
      password: "password123",
      password_confirmation: "password123"
    )

    @field_worker = User.create!(
      organization: @organization,
      email: "field-worker-service-categories@example.com",
      first_name: "Service",
      last_name: "Field Worker",
      role: "field_worker",
      password: "password123",
      password_confirmation: "password123"
    )

    @member = User.create!(
      organization: @organization,
      email: "member-service-categories@example.com",
      first_name: "Service",
      last_name: "Member",
      role: "member",
      password: "password123",
      password_confirmation: "password123"
    )

    @category = ServiceCategory.create!(
      organization: @organization,
      code: "ENT",
      name: "Entretien",
      description: "Entretien courant des espaces verts",
      category_type: "service",
      position: 1,
      active: true
    )

    @other_category = ServiceCategory.create!(
      organization: @other_organization,
      code: "OTH",
      name: "Other Services",
      category_type: "service",
      position: 1,
      active: true
    )

    @owner_token = JwtService.encode(@owner)
    @admin_token = JwtService.encode(@admin)
    @manager_token = JwtService.encode(@manager)
    @accountant_token = JwtService.encode(@accountant)
    @field_worker_token = JwtService.encode(@field_worker)
    @member_token = JwtService.encode(@member)
  end

  test "index requires authentication" do
    get "/api/v1/service_categories"

    assert_response :unauthorized
  end

  test "index returns categories from authenticated user's organization" do
    ServiceCategory.create!(
      organization: @organization,
      code: "CRE",
      name: "Création",
      category_type: "service",
      position: 2,
      active: true
    )

    get "/api/v1/service_categories",
        headers: {
          "Authorization" => "Bearer #{@manager_token}"
        }

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal 2, body.length
    assert_equal @category.id, body.first["id"]
  end

  test "index does not expose categories from another organization" do
    get "/api/v1/service_categories",
        headers: {
          "Authorization" => "Bearer #{@manager_token}"
        }

    assert_response :success

    body = JSON.parse(response.body)

    assert body.none? { |category| category["id"] == @other_category.id }
  end

  test "index returns categories ordered by position" do
    later_category = ServiceCategory.create!(
      organization: @organization,
      code: "CRE",
      name: "Création",
      category_type: "service",
      position: 3,
      active: true
    )

    earlier_category = ServiceCategory.create!(
      organization: @organization,
      code: "ARB",
      name: "Arboriculture",
      category_type: "service",
      position: 0,
      active: true
    )

    get "/api/v1/service_categories",
        headers: {
          "Authorization" => "Bearer #{@manager_token}"
        }

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal earlier_category.id, body.first["id"]
    assert_equal @category.id, body.second["id"]
    assert_equal later_category.id, body.third["id"]
  end

  test "show returns category from same organization" do
    get "/api/v1/service_categories/#{@category.id}",
        headers: {
          "Authorization" => "Bearer #{@manager_token}"
        }

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal @category.id, body["id"]
    assert_equal "ENT", body["code"]
    assert_equal "Entretien", body["name"]
    assert_equal @organization.id, body["organization_id"]
  end

  test "show does not expose category from another organization" do
    get "/api/v1/service_categories/#{@other_category.id}",
        headers: {
          "Authorization" => "Bearer #{@manager_token}"
        }

    assert_response :not_found

    body = JSON.parse(response.body)

    assert_equal "Not Found", body["error"]
  end

  test "show returns not found for a nonexistent category" do
    get "/api/v1/service_categories/00000000-0000-0000-0000-000000000000",
        headers: {
          "Authorization" => "Bearer #{@manager_token}"
        }

    assert_response :not_found
  end

  test "owner can create service category" do
    assert_difference("ServiceCategory.count", 1) do
      post "/api/v1/service_categories",
           params: {
             service_category: {
               code: "TIL",
               name: "Taille",
               description: "Taille des végétaux",
               category_type: "service",
               position: 2,
               active: true
             }
           },
           headers: {
             "Authorization" => "Bearer #{@owner_token}"
           }
    end

    assert_response :created

    body = JSON.parse(response.body)

    assert_equal "TIL", body["code"]
    assert_equal "Taille", body["name"]
    assert_equal @organization.id, body["organization_id"]
  end

  test "admin can create service category" do
    assert_difference("ServiceCategory.count", 1) do
      post "/api/v1/service_categories",
           params: {
             service_category: {
               code: "ADM",
               name: "Administration",
               category_type: "service",
               position: 2
             }
           },
           headers: {
             "Authorization" => "Bearer #{@admin_token}"
           }
    end

    assert_response :created
  end

  test "manager can create service category" do
    assert_difference("ServiceCategory.count", 1) do
      post "/api/v1/service_categories",
           params: {
             service_category: {
               code: "TIL",
               name: "Taille",
               description: "Taille des végétaux",
               category_type: "service",
               position: 2,
               active: true
             }
           },
           headers: {
             "Authorization" => "Bearer #{@manager_token}"
           }
    end

    assert_response :created

    body = JSON.parse(response.body)

    assert_equal "TIL", body["code"]
    assert_equal "Taille", body["name"]
    assert_equal @organization.id, body["organization_id"]
  end

  test "accountant cannot create service category" do
    assert_no_difference("ServiceCategory.count") do
      post "/api/v1/service_categories",
           params: {
             service_category: {
               code: "ACC",
               name: "Unauthorized Accountant Category",
               category_type: "service",
               position: 2
             }
           },
           headers: {
             "Authorization" => "Bearer #{@accountant_token}"
           }
    end

    assert_response :forbidden
  end

  test "field worker cannot create service category" do
    assert_no_difference("ServiceCategory.count") do
      post "/api/v1/service_categories",
           params: {
             service_category: {
               code: "FW",
               name: "Unauthorized Field Worker Category",
               category_type: "service",
               position: 2
             }
           },
           headers: {
             "Authorization" => "Bearer #{@field_worker_token}"
           }
    end

    assert_response :forbidden
  end

  test "member cannot create service category" do
    assert_no_difference("ServiceCategory.count") do
      post "/api/v1/service_categories",
           params: {
             service_category: {
               code: "MEM",
               name: "Unauthorized Member Category",
               category_type: "service",
               position: 2
             }
           },
           headers: {
             "Authorization" => "Bearer #{@member_token}"
           }
    end

    assert_response :forbidden
  end

  test "create always assigns the current user's organization" do
    assert_difference("ServiceCategory.count", 1) do
      post "/api/v1/service_categories",
           params: {
             service_category: {
               organization_id: @other_organization.id,
               code: "TEN",
               name: "Tenant Isolation Test",
               category_type: "service",
               position: 2
             }
           },
           headers: {
             "Authorization" => "Bearer #{@manager_token}"
           }
    end

    assert_response :created

    category = ServiceCategory.order(created_at: :desc).first

    assert_equal @organization.id, category.organization_id
    assert_not_equal @other_organization.id, category.organization_id
  end

  test "create returns unprocessable entity for invalid category" do
    assert_no_difference("ServiceCategory.count") do
      post "/api/v1/service_categories",
           params: {
             service_category: {
               code: nil,
               name: nil,
               category_type: "invalid"
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

  test "duplicate code is rejected within organization" do
    assert_no_difference("ServiceCategory.count") do
      post "/api/v1/service_categories",
           params: {
             service_category: {
               code: "ENT",
               name: "Entretien duplicate",
               category_type: "service",
               position: 5
             }
           },
           headers: {
             "Authorization" => "Bearer #{@manager_token}"
           }
    end

    assert_response :unprocessable_entity

    body = JSON.parse(response.body)

    assert body["messages"].any? { |message| message.include?("Code") }
  end

  test "owner can update service category from same organization" do
    patch "/api/v1/service_categories/#{@category.id}",
          params: {
            service_category: {
              name: "Entretien Owner",
              position: 2
            }
          },
          headers: {
            "Authorization" => "Bearer #{@owner_token}"
          }

    assert_response :success

    @category.reload

    assert_equal "Entretien Owner", @category.name
    assert_equal 2, @category.position
  end

  test "admin can update service category from same organization" do
    patch "/api/v1/service_categories/#{@category.id}",
          params: {
            service_category: {
              name: "Entretien Admin"
            }
          },
          headers: {
            "Authorization" => "Bearer #{@admin_token}"
          }

    assert_response :success

    assert_equal "Entretien Admin", @category.reload.name
  end

  test "manager can update service category from same organization" do
    patch "/api/v1/service_categories/#{@category.id}",
          params: {
            service_category: {
              name: "Entretien Manager",
              position: 3
            }
          },
          headers: {
            "Authorization" => "Bearer #{@manager_token}"
          }

    assert_response :success

    @category.reload

    assert_equal "Entretien Manager", @category.name
    assert_equal 3, @category.position
  end

  test "accountant cannot update service category" do
    patch "/api/v1/service_categories/#{@category.id}",
          params: {
            service_category: {
              name: "Unauthorized Accountant Update"
            }
          },
          headers: {
            "Authorization" => "Bearer #{@accountant_token}"
          }

    assert_response :forbidden

    assert_equal "Entretien", @category.reload.name
  end

  test "field worker cannot update service category" do
    patch "/api/v1/service_categories/#{@category.id}",
          params: {
            service_category: {
              name: "Unauthorized Field Worker Update"
            }
          },
          headers: {
            "Authorization" => "Bearer #{@field_worker_token}"
          }

    assert_response :forbidden

    assert_equal "Entretien", @category.reload.name
  end

  test "member cannot update service category" do
    patch "/api/v1/service_categories/#{@category.id}",
          params: {
            service_category: {
              name: "Unauthorized Member Update"
            }
          },
          headers: {
            "Authorization" => "Bearer #{@member_token}"
          }

    assert_response :forbidden

    assert_equal "Entretien", @category.reload.name
  end

  test "manager cannot update category from another organization" do
    patch "/api/v1/service_categories/#{@other_category.id}",
          params: {
            service_category: {
              name: "Unauthorized update"
            }
          },
          headers: {
            "Authorization" => "Bearer #{@manager_token}"
          }

    assert_response :not_found

    assert_equal "Other Services", @other_category.reload.name
  end

  test "update returns unprocessable entity for invalid category" do
    patch "/api/v1/service_categories/#{@category.id}",
          params: {
            service_category: {
              code: nil,
              name: nil
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

  test "update returns not found for a nonexistent category" do
    patch "/api/v1/service_categories/00000000-0000-0000-0000-000000000000",
          params: {
            service_category: {
              name: "Updated"
            }
          },
          headers: {
            "Authorization" => "Bearer #{@manager_token}"
          }

    assert_response :not_found
  end

  test "owner can destroy service category" do
    assert_difference("ServiceCategory.count", -1) do
      delete "/api/v1/service_categories/#{@category.id}",
             headers: {
               "Authorization" => "Bearer #{@owner_token}"
             }
    end

    assert_response :no_content
  end

  test "admin can destroy service category" do
    category = ServiceCategory.create!(
      organization: @organization,
      code: "DEL",
      name: "Admin Delete",
      category_type: "service",
      position: 2
    )

    assert_difference("ServiceCategory.count", -1) do
      delete "/api/v1/service_categories/#{category.id}",
             headers: {
               "Authorization" => "Bearer #{@admin_token}"
             }
    end

    assert_response :no_content
  end

  test "manager cannot destroy service category" do
    assert_no_difference("ServiceCategory.count") do
      delete "/api/v1/service_categories/#{@category.id}",
             headers: {
               "Authorization" => "Bearer #{@manager_token}"
             }
    end

    assert_response :forbidden
  end

  test "accountant cannot destroy service category" do
    assert_no_difference("ServiceCategory.count") do
      delete "/api/v1/service_categories/#{@category.id}",
             headers: {
               "Authorization" => "Bearer #{@accountant_token}"
             }
    end

    assert_response :forbidden
  end

  test "field worker cannot destroy service category" do
    assert_no_difference("ServiceCategory.count") do
      delete "/api/v1/service_categories/#{@category.id}",
             headers: {
               "Authorization" => "Bearer #{@field_worker_token}"
             }
    end

    assert_response :forbidden
  end

  test "member cannot destroy service category" do
    assert_no_difference("ServiceCategory.count") do
      delete "/api/v1/service_categories/#{@category.id}",
             headers: {
               "Authorization" => "Bearer #{@member_token}"
             }
    end

    assert_response :forbidden
  end

  test "owner cannot destroy category from another organization" do
    assert_no_difference("ServiceCategory.count") do
      delete "/api/v1/service_categories/#{@other_category.id}",
             headers: {
               "Authorization" => "Bearer #{@owner_token}"
             }
    end

    assert_response :not_found

    assert ServiceCategory.exists?(@other_category.id)
  end

  test "destroy returns not found for a nonexistent category" do
    delete "/api/v1/service_categories/00000000-0000-0000-0000-000000000000",
           headers: {
             "Authorization" => "Bearer #{@owner_token}"
           }

    assert_response :not_found
  end
end
