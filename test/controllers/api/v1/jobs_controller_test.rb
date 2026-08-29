require "test_helper"

class Api::V1::JobsControllerTest < ActionDispatch::IntegrationTest
setup do
@organization = Organization.create!(
name: "GreenPilot Jobs Test",
slug: "greenpilot-jobs-test"
)


@other_organization = Organization.create!(
  name: "Other Organization",
  slug: "other-organization-jobs-test"
)

@owner = create_user(
  organization: @organization,
  email: "owner-jobs@example.com",
  role: "owner"
)

@admin = create_user(
  organization: @organization,
  email: "admin-jobs@example.com",
  role: "admin"
)

@manager = create_user(
  organization: @organization,
  email: "manager-jobs@example.com",
  role: "manager"
)

@accountant = create_user(
  organization: @organization,
  email: "accountant-jobs@example.com",
  role: "accountant"
)

@field_worker = create_user(
  organization: @organization,
  email: "field-worker-jobs@example.com",
  role: "field_worker"
)

@member = create_user(
  organization: @organization,
  email: "member-jobs@example.com",
  role: "member"
)

@other_manager = create_user(
  organization: @other_organization,
  email: "other-manager-jobs@example.com",
  role: "manager"
)

@customer = Customer.create!(
  organization: @organization,
  customer_type: "individual",
  first_name: "John",
  last_name: "Customer",
  email: "john-jobs@example.com"
)

@second_customer = Customer.create!(
  organization: @organization,
  customer_type: "individual",
  first_name: "Jane",
  last_name: "Customer",
  email: "jane-jobs@example.com"
)

@other_customer = Customer.create!(
  organization: @other_organization,
  customer_type: "individual",
  first_name: "Other",
  last_name: "Customer",
  email: "other-customer-jobs@example.com"
)

@site = Site.create!(
  organization: @organization,
  customer: @customer,
  name: "Job Test Site"
)

@second_site = Site.create!(
  organization: @organization,
  customer: @second_customer,
  name: "Second Job Site"
)

@other_site = Site.create!(
  organization: @other_organization,
  customer: @other_customer,
  name: "Other Job Site"
)

@quote = Quote.create!(
  organization: @organization,
  customer: @customer,
  site: @site,
  number: "DEV-JOB-0001",
  title: "Job Quote",
  issue_date: Date.current,
  status: "draft"
)

@other_quote = Quote.create!(
  organization: @other_organization,
  customer: @other_customer,
  site: @other_site,
  number: "DEV-OTHER-JOB-0001",
  title: "Other Job Quote",
  issue_date: Date.current,
  status: "draft"
)

@team = Team.create!(
  organization: @organization,
  code: "TEAM-JOB",
  name: "Job Team"
)

@other_team = Team.create!(
  organization: @other_organization,
  code: "OTHER-JOB",
  name: "Other Job Team"
)

@vehicle = Vehicle.create!(
  organization: @organization,
  name: "Job Vehicle",
  registration_number: "JOB-001"
)

@other_vehicle = Vehicle.create!(
  organization: @other_organization,
  name: "Other Job Vehicle",
  registration_number: "OTHER-001"
)

@job = Job.create!(
  organization: @organization,
  customer: @customer,
  site: @site,
  quote: @quote,
  team: @team,
  vehicle: @vehicle,
  title: "Garden Maintenance",
  job_type: "maintenance",
  status: "planned",
  priority: "normal",
  scheduled_date: Date.current,
  weather_risk: "unknown"
)

@other_job = Job.create!(
  organization: @other_organization,
  customer: @other_customer,
  site: @other_site,
  quote: @other_quote,
  team: @other_team,
  vehicle: @other_vehicle,
  title: "Other Organization Job",
  job_type: "maintenance",
  status: "planned",
  priority: "normal",
  scheduled_date: Date.current,
  weather_risk: "unknown"
)

JobAssignment.create!(
  organization: @organization,
  job: @job,
  user: @field_worker,
  assignment_type: "worker",
  role: "worker",
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
get "/api/v1/jobs"


assert_response :unauthorized
end

test "index returns jobs from the current organization" do
get "/api/v1/jobs",
headers: {
"Authorization" => "Bearer #{@manager_token}"
}


assert_response :success

body = JSON.parse(response.body)

assert_equal 1, body.length
assert_equal @job.id, body.first["id"]
assert_equal @organization.id, body.first["organization_id"]
end

test "index does not expose jobs from another organization" do
get "/api/v1/jobs",
headers: {
"Authorization" => "Bearer #{@manager_token}"
}


assert_response :success

body = JSON.parse(response.body)

assert body.none? { |job| job["id"] == @other_job.id }
assert body.none? { |job| job["organization_id"] == @other_organization.id }
end

test "index can filter jobs by date" do
future_job = Job.create!(
organization: @organization,
customer: @customer,
site: @site,
title: "Future Job",
job_type: "maintenance",
status: "planned",
priority: "normal",
weather_risk: "unknown",
scheduled_date: Date.current + 7.days
)


get "/api/v1/jobs",
    params: {
      date: (Date.current + 7.days).to_s
    },
    headers: {
      "Authorization" => "Bearer #{@manager_token}"
    }

assert_response :success

body = JSON.parse(response.body)

assert_equal 1, body.length
assert_equal future_job.id, body.first["id"]
end

test "index can filter jobs by status" do
completed_job = Job.create!(
organization: @organization,
customer: @customer,
site: @site,
title: "Completed Job",
job_type: "maintenance",
status: "completed",
priority: "normal",
weather_risk: "unknown",
scheduled_date: Date.current,
started_at: Time.current,
completed_at: Time.current + 1.hour
)


get "/api/v1/jobs",
    params: {
      status: "completed"
    },
    headers: {
      "Authorization" => "Bearer #{@manager_token}"
    }

assert_response :success

body = JSON.parse(response.body)

assert_equal 1, body.length
assert_equal completed_job.id, body.first["id"]
end

test "index can filter jobs by priority" do
urgent_job = Job.create!(
organization: @organization,
customer: @customer,
site: @site,
title: "Urgent Job",
job_type: "emergency",
status: "planned",
priority: "urgent",
weather_risk: "high",
scheduled_date: Date.current
)


get "/api/v1/jobs",
    params: {
      priority: "urgent"
    },
    headers: {
      "Authorization" => "Bearer #{@manager_token}"
    }

assert_response :success

body = JSON.parse(response.body)

assert_equal 1, body.length
assert_equal urgent_job.id, body.first["id"]
end

test "index can combine date status and priority filters" do
matching_job = Job.create!(
organization: @organization,
customer: @customer,
site: @site,
title: "Matching Job",
job_type: "maintenance",
status: "in_progress",
priority: "high",
weather_risk: "medium",
scheduled_date: Date.current + 2.days
)


Job.create!(
  organization: @organization,
  customer: @customer,
  site: @site,
  title: "Non Matching Job",
  job_type: "maintenance",
  status: "planned",
  priority: "high",
  weather_risk: "unknown",
  scheduled_date: Date.current + 2.days
)

get "/api/v1/jobs",
    params: {
      date: (Date.current + 2.days).to_s,
      status: "in_progress",
      priority: "high"
    },
    headers: {
      "Authorization" => "Bearer #{@manager_token}"
    }

assert_response :success

body = JSON.parse(response.body)

assert_equal 1, body.length
assert_equal matching_job.id, body.first["id"]
end

test "show returns a job from the same organization" do
get "/api/v1/jobs/#{@job.id}",
headers: {
"Authorization" => "Bearer #{@manager_token}"
}


assert_response :success

body = JSON.parse(response.body)

assert_equal @job.id, body["id"]
assert_equal @organization.id, body["organization_id"]
assert_equal @customer.id, body["customer_id"]
assert_equal @site.id, body["site_id"]
end

test "show cannot access a job from another organization" do
get "/api/v1/jobs/#{@other_job.id}",
headers: {
"Authorization" => "Bearer #{@manager_token}"
}


assert_response :not_found
end

test "show returns not found for a nonexistent job" do
get "/api/v1/jobs/00000000-0000-0000-0000-000000000000",
headers: {
"Authorization" => "Bearer #{@manager_token}"
}


assert_response :not_found
end

test "owner can create a job" do
assert_difference("Job.count", 1) do
post "/api/v1/jobs",
params: {
job: {
customer_id: @customer.id,
site_id: @site.id,
team_id: @team.id,
vehicle_id: @vehicle.id,
quote_id: @quote.id,
title: "Owner Job",
job_type: "maintenance",
status: "planned",
priority: "normal",
weather_risk: "unknown",
scheduled_date: Date.current
}
},
headers: {
"Authorization" => "Bearer #{@owner_token}"
}
end


assert_response :created
end

test "admin can create a job" do
assert_difference("Job.count", 1) do
post "/api/v1/jobs",
params: {
job: {
customer_id: @customer.id,
site_id: @site.id,
title: "Admin Job",
job_type: "maintenance",
status: "planned",
priority: "normal",
weather_risk: "unknown",
scheduled_date: Date.current
}
},
headers: {
"Authorization" => "Bearer #{@admin_token}"
}
end


assert_response :created
end

test "manager can create a job" do
assert_difference("Job.count", 1) do
post "/api/v1/jobs",
params: {
job: {
customer_id: @customer.id,
site_id: @site.id,
team_id: @team.id,
vehicle_id: @vehicle.id,
quote_id: @quote.id,
title: "New Garden Job",
job_type: "maintenance",
status: "planned",
priority: "normal",
weather_risk: "unknown",
scheduled_date: Date.current
}
},
headers: {
"Authorization" => "Bearer #{@manager_token}"
}
end


assert_response :created

body = JSON.parse(response.body)

assert_equal "New Garden Job", body["title"]
assert_equal @organization.id, body["organization_id"]
assert_equal @customer.id, body["customer_id"]
assert_equal @site.id, body["site_id"]
end

test "accountant cannot create a job" do
assert_no_difference("Job.count") do
post "/api/v1/jobs",
params: {
job: {
customer_id: @customer.id,
site_id: @site.id,
title: "Accountant Job",
job_type: "maintenance",
status: "planned",
priority: "normal",
weather_risk: "unknown",
scheduled_date: Date.current
}
},
headers: {
"Authorization" => "Bearer #{@accountant_token}"
}
end


assert_response :forbidden
end

test "field worker cannot create a job" do
assert_no_difference("Job.count") do
post "/api/v1/jobs",
params: {
job: {
customer_id: @customer.id,
site_id: @site.id,
title: "Field Worker Job",
job_type: "maintenance",
status: "planned",
priority: "normal",
weather_risk: "unknown",
scheduled_date: Date.current
}
},
headers: {
"Authorization" => "Bearer #{@field_worker_token}"
}
end


assert_response :forbidden
end

test "member cannot create a job" do
assert_no_difference("Job.count") do
post "/api/v1/jobs",
params: {
job: {
customer_id: @customer.id,
site_id: @site.id,
title: "Unauthorized Job",
job_type: "maintenance",
status: "planned",
priority: "normal",
weather_risk: "unknown",
scheduled_date: Date.current
}
},
headers: {
"Authorization" => "Bearer #{@member_token}"
}
end


assert_response :forbidden
end

test "create always assigns the current user's organization" do
assert_difference("Job.count", 1) do
post "/api/v1/jobs",
params: {
job: {
organization_id: @other_organization.id,
customer_id: @customer.id,
site_id: @site.id,
title: "Tenant Isolation Job",
job_type: "maintenance",
status: "planned",
priority: "normal",
weather_risk: "unknown",
scheduled_date: Date.current
}
},
headers: {
"Authorization" => "Bearer #{@manager_token}"
}
end


assert_response :created

job = Job.order(created_at: :desc).first

assert_equal @organization.id, job.organization_id
assert_not_equal @other_organization.id, job.organization_id
end

test "cannot create a job with customer from another organization" do
assert_no_difference("Job.count") do
post "/api/v1/jobs",
params: {
job: {
customer_id: @other_customer.id,
site_id: @site.id,
title: "Cross Organization Job",
job_type: "maintenance",
status: "planned",
priority: "normal",
weather_risk: "unknown",
scheduled_date: Date.current
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
                "Customer must belong to the same organization"
end

test "cannot create a job with site from another organization" do
assert_no_difference("Job.count") do
post "/api/v1/jobs",
params: {
job: {
customer_id: @customer.id,
site_id: @other_site.id,
title: "Cross Organization Site Job",
job_type: "maintenance",
status: "planned",
priority: "normal",
weather_risk: "unknown",
scheduled_date: Date.current
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

test "cannot create a job with site from another customer" do
assert_no_difference("Job.count") do
post "/api/v1/jobs",
params: {
job: {
customer_id: @customer.id,
site_id: @second_site.id,
title: "Cross Customer Site Job",
job_type: "maintenance",
status: "planned",
priority: "normal",
weather_risk: "unknown",
scheduled_date: Date.current
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

test "cannot create a job with quote from another organization" do
assert_no_difference("Job.count") do
post "/api/v1/jobs",
params: {
job: {
customer_id: @customer.id,
site_id: @site.id,
quote_id: @other_quote.id,
title: "Cross Organization Quote Job",
job_type: "maintenance",
status: "planned",
priority: "normal",
weather_risk: "unknown",
scheduled_date: Date.current
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
                "Quote must belong to the same organization"
end

test "cannot create a job with team from another organization" do
assert_no_difference("Job.count") do
post "/api/v1/jobs",
params: {
job: {
customer_id: @customer.id,
site_id: @site.id,
team_id: @other_team.id,
title: "Cross Organization Team Job",
job_type: "maintenance",
status: "planned",
priority: "normal",
weather_risk: "unknown",
scheduled_date: Date.current
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
                "Team must belong to the same organization"
end

test "cannot create a job with vehicle from another organization" do
assert_no_difference("Job.count") do
post "/api/v1/jobs",
params: {
job: {
customer_id: @customer.id,
site_id: @site.id,
vehicle_id: @other_vehicle.id,
title: "Cross Organization Vehicle Job",
job_type: "maintenance",
status: "planned",
priority: "normal",
weather_risk: "unknown",
scheduled_date: Date.current
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
                "Vehicle must belong to the same organization"
end

test "create returns unprocessable entity for invalid job" do
assert_no_difference("Job.count") do
post "/api/v1/jobs",
params: {
job: {
customer_id: @customer.id,
site_id: @site.id,
title: nil,
job_type: nil,
status: "invalid",
priority: "invalid",
weather_risk: "invalid"
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

test "manager can update a job" do
patch "/api/v1/jobs/#{@job.id}",
params: {
job: {
title: "Updated Garden Job"
}
},
headers: {
"Authorization" => "Bearer #{@manager_token}"
}


assert_response :success

assert_equal "Updated Garden Job", @job.reload.title
end

test "owner can update a job" do
patch "/api/v1/jobs/#{@job.id}",
params: {
job: {
title: "Owner Updated Job"
}
},
headers: {
"Authorization" => "Bearer #{@owner_token}"
}


assert_response :success

assert_equal "Owner Updated Job", @job.reload.title
end

test "admin can update a job" do
patch "/api/v1/jobs/#{@job.id}",
params: {
job: {
title: "Admin Updated Job"
}
},
headers: {
"Authorization" => "Bearer #{@admin_token}"
}


assert_response :success

assert_equal "Admin Updated Job", @job.reload.title
end

test "assigned field worker can update a job" do
patch "/api/v1/jobs/#{@job.id}",
params: {
job: {
status: "in_progress"
}
},
headers: {
"Authorization" => "Bearer #{@field_worker_token}"
}


assert_response :success

assert_equal "in_progress", @job.reload.status
end

test "unassigned field worker cannot update a job" do
unassigned_worker = create_user(
organization: @organization,
email: "unassigned-worker@example.com",
role: "field_worker"
)


token = JwtService.encode(unassigned_worker)

patch "/api/v1/jobs/#{@job.id}",
      params: {
        job: {
          status: "in_progress"
        }
      },
      headers: {
        "Authorization" => "Bearer #{token}"
      }

assert_response :forbidden

assert_equal "planned", @job.reload.status
end

test "accountant cannot update a job" do
patch "/api/v1/jobs/#{@job.id}",
params: {
job: {
title: "Unauthorized Accountant Update"
}
},
headers: {
"Authorization" => "Bearer #{@accountant_token}"
}

assert_response :forbidden

assert_equal "Garden Maintenance", @job.reload.title
end

test "member cannot update a job" do
patch "/api/v1/jobs/#{@job.id}",
params: {
job: {
title: "Unauthorized Update"
}
},
headers: {
"Authorization" => "Bearer #{@member_token}"
}


assert_response :forbidden

assert_equal "Garden Maintenance", @job.reload.title
end

test "manager cannot update a job from another organization" do
patch "/api/v1/jobs/#{@other_job.id}",
params: {
job: {
title: "Unauthorized Cross Organization Update"
}
},
headers: {
"Authorization" => "Bearer #{@manager_token}"
}


assert_response :not_found

assert_equal "Other Organization Job", @other_job.reload.title
end

test "manager cannot update job to customer from another organization" do
patch "/api/v1/jobs/#{@job.id}",
params: {
job: {
customer_id: @other_customer.id
}
},
headers: {
"Authorization" => "Bearer #{@manager_token}"
}


assert_response :unprocessable_entity

assert_equal @customer.id, @job.reload.customer_id
end

test "manager cannot update job to site from another organization" do
patch "/api/v1/jobs/#{@job.id}",
params: {
job: {
site_id: @other_site.id
}
},
headers: {
"Authorization" => "Bearer #{@manager_token}"
}


assert_response :unprocessable_entity

assert_equal @site.id, @job.reload.site_id
end

test "manager cannot update job to site from another customer" do
patch "/api/v1/jobs/#{@job.id}",
params: {
job: {
site_id: @second_site.id
}
},
headers: {
"Authorization" => "Bearer #{@manager_token}"
}


assert_response :unprocessable_entity

assert_equal @site.id, @job.reload.site_id
end

test "manager cannot update job to quote from another organization" do
patch "/api/v1/jobs/#{@job.id}",
params: {
job: {
quote_id: @other_quote.id
}
},
headers: {
"Authorization" => "Bearer #{@manager_token}"
}


assert_response :unprocessable_entity

assert_equal @quote.id, @job.reload.quote_id
end

test "manager cannot update job to team from another organization" do
patch "/api/v1/jobs/#{@job.id}",
params: {
job: {
team_id: @other_team.id
}
},
headers: {
"Authorization" => "Bearer #{@manager_token}"
}


assert_response :unprocessable_entity

assert_equal @team.id, @job.reload.team_id
end

test "manager cannot update job to vehicle from another organization" do
patch "/api/v1/jobs/#{@job.id}",
params: {
job: {
vehicle_id: @other_vehicle.id
}
},
headers: {
"Authorization" => "Bearer #{@manager_token}"
}


assert_response :unprocessable_entity

assert_equal @vehicle.id, @job.reload.vehicle_id
end

test "update returns unprocessable entity for invalid job" do
patch "/api/v1/jobs/#{@job.id}",
params: {
job: {
title: nil,
job_type: nil,
status: "invalid",
priority: "invalid",
weather_risk: "invalid"
}
},
headers: {
"Authorization" => "Bearer #{@manager_token}"
}


assert_response :unprocessable_entity

body = JSON.parse(response.body)

assert_equal "Unprocessable Entity", body["error"]
assert body["messages"].any?

@job.reload

assert_equal "Garden Maintenance", @job.title
assert_equal "maintenance", @job.job_type
assert_equal "planned", @job.status
end

test "update rejects scheduled end before scheduled start" do
start_time = Time.current.change(sec: 0)


patch "/api/v1/jobs/#{@job.id}",
      params: {
        job: {
          scheduled_start_at: start_time,
          scheduled_end_at: start_time - 1.hour
        }
      },
      headers: {
        "Authorization" => "Bearer #{@manager_token}"
      }

assert_response :unprocessable_entity

body = JSON.parse(response.body)

assert_includes body["messages"],
                "Scheduled end at must be after scheduled start time"
end

test "update rejects started time before scheduled start time" do
start_time = Time.current.change(sec: 0)


patch "/api/v1/jobs/#{@job.id}",
      params: {
        job: {
          scheduled_start_at: start_time,
          started_at: start_time - 1.hour
        }
      },
      headers: {
        "Authorization" => "Bearer #{@manager_token}"
      }

assert_response :unprocessable_entity

body = JSON.parse(response.body)

assert_includes body["messages"],
                "Started at cannot be before scheduled start time"
end

test "update rejects completed time before started time" do
started_at = Time.current.change(sec: 0)


patch "/api/v1/jobs/#{@job.id}",
      params: {
        job: {
          started_at: started_at,
          completed_at: started_at - 1.hour
        }
      },
      headers: {
        "Authorization" => "Bearer #{@manager_token}"
      }

assert_response :unprocessable_entity

body = JSON.parse(response.body)

assert_includes body["messages"],
                "Completed at cannot be before started time"
end

test "update rejects completed status without completed_at" do
patch "/api/v1/jobs/#{@job.id}",
params: {
job: {
status: "completed"
}
},
headers: {
"Authorization" => "Bearer #{@manager_token}"
}


assert_response :unprocessable_entity

body = JSON.parse(response.body)

assert_includes body["messages"],
                "Completed at must be present when job is completed"
end

test "update rejects cancelled status without cancelled_at" do
patch "/api/v1/jobs/#{@job.id}",
params: {
job: {
status: "cancelled"
}
},
headers: {
"Authorization" => "Bearer #{@manager_token}"
}


assert_response :unprocessable_entity

body = JSON.parse(response.body)

assert_includes body["messages"],
                "Cancelled at must be present when job is cancelled"
end

test "update returns not found for a nonexistent job" do
patch "/api/v1/jobs/00000000-0000-0000-0000-000000000000",
params: {
job: {
title: "Updated"
}
},
headers: {
"Authorization" => "Bearer #{@manager_token}"
}


assert_response :not_found
end

test "owner can destroy a job" do
assert_difference("Job.count", -1) do
delete "/api/v1/jobs/#{@job.id}",
headers: {
"Authorization" => "Bearer #{@owner_token}"
}
end


assert_response :no_content
end

test "admin can destroy a job" do
job = Job.create!(
organization: @organization,
customer: @customer,
site: @site,
title: "Admin Delete Job",
job_type: "maintenance",
status: "planned",
priority: "normal",
weather_risk: "unknown"
)


assert_difference("Job.count", -1) do
  delete "/api/v1/jobs/#{job.id}",
         headers: {
           "Authorization" => "Bearer #{@admin_token}"
         }
end

assert_response :no_content
end

test "manager cannot destroy a job" do
assert_no_difference("Job.count") do
delete "/api/v1/jobs/#{@job.id}",
headers: {
"Authorization" => "Bearer #{@manager_token}"
}
end


assert_response :forbidden
assert Job.exists?(@job.id)
end

test "accountant cannot destroy a job" do
assert_no_difference("Job.count") do
delete "/api/v1/jobs/#{@job.id}",
headers: {
"Authorization" => "Bearer #{@accountant_token}"
}
end


assert_response :forbidden
assert Job.exists?(@job.id)
end

test "field worker cannot destroy a job" do
assert_no_difference("Job.count") do
delete "/api/v1/jobs/#{@job.id}",
headers: {
"Authorization" => "Bearer #{@field_worker_token}"
}
end


assert_response :forbidden
assert Job.exists?(@job.id)
end

test "member cannot destroy a job" do
assert_no_difference("Job.count") do
delete "/api/v1/jobs/#{@job.id}",
headers: {
"Authorization" => "Bearer #{@member_token}"
}
end


assert_response :forbidden
assert Job.exists?(@job.id)
end

test "owner cannot destroy a job from another organization" do
assert_no_difference("Job.count") do
delete "/api/v1/jobs/#{@other_job.id}",
headers: {
"Authorization" => "Bearer #{@owner_token}"
}
end


assert_response :not_found
assert Job.exists?(@other_job.id)
end

test "destroy returns not found for a nonexistent job" do
delete "/api/v1/jobs/00000000-0000-0000-0000-000000000000",
headers: {
"Authorization" => "Bearer #{@owner_token}"
}


assert_response :not_found
end
end
