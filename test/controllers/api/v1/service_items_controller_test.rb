require "test_helper"

class Api::V1::ServiceItemsControllerTest < ActionDispatch::IntegrationTest
setup do
@organization = Organization.create!(
name: "GreenPilot Service Items Test",
slug: "greenpilot-service-items-test"
)


@other_organization = Organization.create!(
  name: "Other Service Items Organization",
  slug: "other-service-items-org"
)

@owner = User.create!(
  organization: @organization,
  email: "owner-service-items@example.com",
  first_name: "Service",
  last_name: "Item Owner",
  role: "owner",
  password: "password123",
  password_confirmation: "password123"
)

@admin = User.create!(
  organization: @organization,
  email: "admin-service-items@example.com",
  first_name: "Service",
  last_name: "Item Admin",
  role: "admin",
  password: "password123",
  password_confirmation: "password123"
)

@manager = User.create!(
  organization: @organization,
  email: "manager-service-items@example.com",
  first_name: "Service",
  last_name: "Item Manager",
  role: "manager",
  password: "password123",
  password_confirmation: "password123"
)

@accountant = User.create!(
  organization: @organization,
  email: "accountant-service-items@example.com",
  first_name: "Service",
  last_name: "Item Accountant",
  role: "accountant",
  password: "password123",
  password_confirmation: "password123"
)

@field_worker = User.create!(
  organization: @organization,
  email: "field-worker-service-items@example.com",
  first_name: "Service",
  last_name: "Item Field Worker",
  role: "field_worker",
  password: "password123",
  password_confirmation: "password123"
)

@member = User.create!(
  organization: @organization,
  email: "member-service-items@example.com",
  first_name: "Service",
  last_name: "Item Member",
  role: "member",
  password: "password123",
  password_confirmation: "password123"
)

@other_manager = User.create!(
  organization: @other_organization,
  email: "other-manager-service-items@example.com",
  first_name: "Other",
  last_name: "Manager",
  role: "manager",
  password: "password123",
  password_confirmation: "password123"
)

@category = ServiceCategory.create!(
  organization: @organization,
  code: "ENT",
  name: "Entretien",
  position: 1,
  active: true
)

@second_category = ServiceCategory.create!(
  organization: @organization,
  code: "CRE",
  name: "Création",
  position: 2,
  active: true
)

@third_category = ServiceCategory.create!(
  organization: @organization,
  code: "ARB",
  name: "Arboriculture",
  position: 3,
  active: true
)

@other_category = ServiceCategory.create!(
  organization: @other_organization,
  code: "OTH",
  name: "Other Services",
  position: 1,
  active: true
)

@service_item = ServiceItem.create!(
  organization: @organization,
  service_category: @category,
  code: "TONTE",
  name: "Tonte de pelouse",
  description: "Tonte classique",
  default_quantity: 1.0,
  default_unit_price: 45.0,
  default_margin_percentage: 30.0,
  labor_cost: 20.0,
  material_cost: 2.0,
  equipment_cost: 5.0,
  overhead_cost: 3.0,
  estimated_duration_minutes: 60,
  unit: "hour",
  position: 1,
  active: true
)

@other_service_item = ServiceItem.create!(
  organization: @other_organization,
  service_category: @other_category,
  code: "OTHER",
  name: "Other Service",
  position: 1,
  active: true
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
get "/api/v1/service_items"


assert_response :unauthorized


end

test "index returns service items from authenticated user's organization" do
second_item = ServiceItem.create!(
organization: @organization,
service_category: @second_category,
code: "TAILLE",
name: "Taille de haies",
position: 2
)


get "/api/v1/service_items",
    headers: {
      "Authorization" => "Bearer #{@manager_token}"
    }

assert_response :success

body = JSON.parse(response.body)

assert_equal 2, body.length
assert_equal @service_item.id, body.first["id"]
assert_equal second_item.id, body.second["id"]


end

test "index does not expose service items from another organization" do
get "/api/v1/service_items",
headers: {
"Authorization" => "Bearer #{@manager_token}"
}


assert_response :success

body = JSON.parse(response.body)

assert body.none? { |item| item["id"] == @other_service_item.id }


end

test "index returns service items ordered by position then name" do
later_item = ServiceItem.create!(
organization: @organization,
service_category: @third_category,
code: "ELAG",
name: "Élagage",
position: 3
)


earlier_item = ServiceItem.create!(
  organization: @organization,
  service_category: @second_category,
  code: "DEBROUS",
  name: "Débroussaillage",
  position: 0
)

same_position_later_name = ServiceItem.create!(
  organization: @organization,
  service_category: @second_category,
  code: "TAILLE",
  name: "Taille",
  position: 2
)

same_position_earlier_name = ServiceItem.create!(
  organization: @organization,
  service_category: @second_category,
  code: "ARROSAGE",
  name: "Arrosage",
  position: 2
)

get "/api/v1/service_items",
    headers: {
      "Authorization" => "Bearer #{@manager_token}"
    }

assert_response :success

body = JSON.parse(response.body)

assert_equal earlier_item.id, body.first["id"]
assert_equal @service_item.id, body.second["id"]
assert_equal same_position_earlier_name.id, body.third["id"]
assert_equal same_position_later_name.id, body.fourth["id"]
assert_equal later_item.id, body.fifth["id"]


end

test "show returns service item from same organization" do
get "/api/v1/service_items/#{@service_item.id}",
headers: {
"Authorization" => "Bearer #{@manager_token}"
}


assert_response :success

body = JSON.parse(response.body)

assert_equal @service_item.id, body["id"]
assert_equal "TONTE", body["code"]
assert_equal "Tonte de pelouse", body["name"]
assert_equal @category.id, body["service_category_id"]
assert_equal @organization.id, body["organization_id"]


end

test "show does not expose service item from another organization" do
get "/api/v1/service_items/#{@other_service_item.id}",
headers: {
"Authorization" => "Bearer #{@manager_token}"
}


assert_response :not_found

body = JSON.parse(response.body)

assert_equal "Not Found", body["error"]


end

test "show returns not found for a nonexistent service item" do
get "/api/v1/service_items/00000000-0000-0000-0000-000000000000",
headers: {
"Authorization" => "Bearer #{@manager_token}"
}


assert_response :not_found


end

test "owner can create service item" do
assert_difference("ServiceItem.count", 1) do
post "/api/v1/service_items",
params: {
service_item: {
service_category_id: @category.id,
code: "DEBROUS",
name: "Débroussaillage",
description: "Débroussaillage des espaces verts",
default_quantity: 1.0,
default_unit_price: 75.0,
default_margin_percentage: 30.0,
labor_cost: 30.0,
material_cost: 5.0,
equipment_cost: 10.0,
overhead_cost: 5.0,
estimated_duration_minutes: 90,
unit: "hour",
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

assert_equal "DEBROUS", body["code"]
assert_equal "Débroussaillage", body["name"]
assert_equal @category.id, body["service_category_id"]
assert_equal @organization.id, body["organization_id"]


end

test "admin can create service item" do
assert_difference("ServiceItem.count", 1) do
post "/api/v1/service_items",
params: {
service_item: {
service_category_id: @category.id,
code: "ADM",
name: "Service administratif",
position: 2
}
},
headers: {
"Authorization" => "Bearer #{@admin_token}"
}
end


assert_response :created


end

test "manager can create service item" do
assert_difference("ServiceItem.count", 1) do
post "/api/v1/service_items",
params: {
service_item: {
service_category_id: @category.id,
code: "DEBROUS",
name: "Débroussaillage",
description: "Débroussaillage des espaces verts",
default_quantity: 1.0,
default_unit_price: 75.0,
default_margin_percentage: 30.0,
labor_cost: 30.0,
material_cost: 5.0,
equipment_cost: 10.0,
overhead_cost: 5.0,
estimated_duration_minutes: 90,
unit: "hour",
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

assert_equal "DEBROUS", body["code"]
assert_equal @category.id, body["service_category_id"]
assert_equal @organization.id, body["organization_id"]


end

test "accountant cannot create service item" do
assert_no_difference("ServiceItem.count") do
post "/api/v1/service_items",
params: {
service_item: {
service_category_id: @category.id,
code: "ACC",
name: "Unauthorized Accountant Item"
}
},
headers: {
"Authorization" => "Bearer #{@accountant_token}"
}
end


assert_response :forbidden


end

test "field worker cannot create service item" do
assert_no_difference("ServiceItem.count") do
post "/api/v1/service_items",
params: {
service_item: {
service_category_id: @category.id,
code: "FW",
name: "Unauthorized Field Worker Item"
}
},
headers: {
"Authorization" => "Bearer #{@field_worker_token}"
}
end


assert_response :forbidden


end

test "member cannot create service item" do
assert_no_difference("ServiceItem.count") do
post "/api/v1/service_items",
params: {
service_item: {
service_category_id: @category.id,
code: "MEM",
name: "Unauthorized Member Item"
}
},
headers: {
"Authorization" => "Bearer #{@member_token}"
}
end


assert_response :forbidden


end

test "manager cannot create service item with category from another organization" do
assert_no_difference("ServiceItem.count") do
post "/api/v1/service_items",
params: {
service_item: {
service_category_id: @other_category.id,
code: "HACK",
name: "Invalid Service Item"
}
},
headers: {
"Authorization" => "Bearer #{@manager_token}"
}
end


assert_response :forbidden


end

test "create always assigns the current user's organization" do
assert_difference("ServiceItem.count", 1) do
post "/api/v1/service_items",
params: {
service_item: {
organization_id: @other_organization.id,
service_category_id: @category.id,
code: "TEN",
name: "Tenant Isolation Test"
}
},
headers: {
"Authorization" => "Bearer #{@manager_token}"
}
end


assert_response :created

item = ServiceItem.order(created_at: :desc).first

assert_equal @organization.id, item.organization_id
assert_not_equal @other_organization.id, item.organization_id


end

test "create returns unprocessable entity for invalid service item" do
assert_no_difference("ServiceItem.count") do
post "/api/v1/service_items",
params: {
service_item: {
service_category_id: @category.id,
code: nil,
name: nil
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
assert_no_difference("ServiceItem.count") do
post "/api/v1/service_items",
params: {
service_item: {
service_category_id: @category.id,
code: "TONTE",
name: "Tonte duplicate"
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

test "same code is allowed in another organization" do
assert_difference("ServiceItem.count", 1) do
post "/api/v1/service_items",
params: {
service_item: {
service_category_id: @other_category.id,
code: "TONTE",
name: "Other Organization Tonte"
}
},
headers: {
"Authorization" => "Bearer #{@other_manager_token}"
}
end


assert_response :created

item = ServiceItem.order(created_at: :desc).first

assert_equal "TONTE", item.code
assert_equal @other_organization.id, item.organization_id


end

test "owner can update service item from same organization" do
patch "/api/v1/service_items/#{@service_item.id}",
params: {
service_item: {
name: "Tonte Owner",
default_unit_price: 55.0,
estimated_duration_minutes: 75
}
},
headers: {
"Authorization" => "Bearer #{@owner_token}"
}


assert_response :success

@service_item.reload

assert_equal "Tonte Owner", @service_item.name
assert_equal 55.0, @service_item.default_unit_price.to_f
assert_equal 75, @service_item.estimated_duration_minutes


end

test "admin can update service item from same organization" do
patch "/api/v1/service_items/#{@service_item.id}",
params: {
service_item: {
name: "Tonte Admin"
}
},
headers: {
"Authorization" => "Bearer #{@admin_token}"
}


assert_response :success

assert_equal "Tonte Admin", @service_item.reload.name


end

test "manager can update service item from same organization" do
patch "/api/v1/service_items/#{@service_item.id}",
params: {
service_item: {
name: "Tonte Manager"
}
},
headers: {
"Authorization" => "Bearer #{@manager_token}"
}


assert_response :success

assert_equal "Tonte Manager", @service_item.reload.name


end

test "accountant cannot update service item" do
patch "/api/v1/service_items/#{@service_item.id}",
params: {
service_item: {
name: "Unauthorized Accountant Update"
}
},
headers: {
"Authorization" => "Bearer #{@accountant_token}"
}


assert_response :forbidden

assert_equal "Tonte de pelouse", @service_item.reload.name


end

test "field worker cannot update service item" do
patch "/api/v1/service_items/#{@service_item.id}",
params: {
service_item: {
name: "Unauthorized Field Worker Update"
}
},
headers: {
"Authorization" => "Bearer #{@field_worker_token}"
}


assert_response :forbidden

assert_equal "Tonte de pelouse", @service_item.reload.name


end

test "member cannot update service item" do
patch "/api/v1/service_items/#{@service_item.id}",
params: {
service_item: {
name: "Unauthorized Member Update"
}
},
headers: {
"Authorization" => "Bearer #{@member_token}"
}


assert_response :forbidden

assert_equal "Tonte de pelouse", @service_item.reload.name


end

test "manager cannot update service item from another organization" do
patch "/api/v1/service_items/#{@other_service_item.id}",
params: {
service_item: {
name: "Unauthorized update"
}
},
headers: {
"Authorization" => "Bearer #{@manager_token}"
}


assert_response :not_found

assert_equal "Other Service", @other_service_item.reload.name


end

test "manager cannot update service item to category from another organization" do
patch "/api/v1/service_items/#{@service_item.id}",
params: {
service_item: {
service_category_id: @other_category.id
}
},
headers: {
"Authorization" => "Bearer #{@manager_token}"
}


assert_response :unprocessable_entity

@service_item.reload

assert_equal @category.id, @service_item.service_category_id


end

test "update can move service item to another category in same organization" do
patch "/api/v1/service_items/#{@service_item.id}",
params: {
service_item: {
service_category_id: @second_category.id
}
},
headers: {
"Authorization" => "Bearer #{@manager_token}"
}


assert_response :success

assert_equal @second_category.id, @service_item.reload.service_category_id


end

test "update returns unprocessable entity for invalid service item" do
patch "/api/v1/service_items/#{@service_item.id}",
params: {
service_item: {
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

test "update returns not found for a nonexistent service item" do
patch "/api/v1/service_items/00000000-0000-0000-0000-000000000000",
params: {
service_item: {
name: "Updated"
}
},
headers: {
"Authorization" => "Bearer #{@manager_token}"
}


assert_response :not_found


end

test "owner can destroy service item" do
assert_difference("ServiceItem.count", -1) do
delete "/api/v1/service_items/#{@service_item.id}",
headers: {
"Authorization" => "Bearer #{@owner_token}"
}
end


assert_response :no_content


end

test "admin can destroy service item" do
item = ServiceItem.create!(
organization: @organization,
service_category: @category,
code: "DEL",
name: "Admin Delete",
position: 2
)


assert_difference("ServiceItem.count", -1) do
  delete "/api/v1/service_items/#{item.id}",
         headers: {
           "Authorization" => "Bearer #{@admin_token}"
         }
end

assert_response :no_content


end

test "manager cannot destroy service item" do
assert_no_difference("ServiceItem.count") do
delete "/api/v1/service_items/#{@service_item.id}",
headers: {
"Authorization" => "Bearer #{@manager_token}"
}
end


assert_response :forbidden


end

test "accountant cannot destroy service item" do
assert_no_difference("ServiceItem.count") do
delete "/api/v1/service_items/#{@service_item.id}",
headers: {
"Authorization" => "Bearer #{@accountant_token}"
}
end


assert_response :forbidden


end

test "field worker cannot destroy service item" do
assert_no_difference("ServiceItem.count") do
delete "/api/v1/service_items/#{@service_item.id}",
headers: {
"Authorization" => "Bearer #{@field_worker_token}"
}
end


assert_response :forbidden


end

test "member cannot destroy service item" do
assert_no_difference("ServiceItem.count") do
delete "/api/v1/service_items/#{@service_item.id}",
headers: {
"Authorization" => "Bearer #{@member_token}"
}
end


assert_response :forbidden


end

test "owner cannot destroy service item from another organization" do
assert_no_difference("ServiceItem.count") do
delete "/api/v1/service_items/#{@other_service_item.id}",
headers: {
"Authorization" => "Bearer #{@owner_token}"
}
end


assert_response :not_found

assert ServiceItem.exists?(@other_service_item.id)


end

test "destroy returns not found for a nonexistent service item" do
delete "/api/v1/service_items/00000000-0000-0000-0000-000000000000",
headers: {
"Authorization" => "Bearer #{@owner_token}"
}


assert_response :not_found


 end

end
