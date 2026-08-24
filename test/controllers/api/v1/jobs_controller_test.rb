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

    @manager = create_user(
      organization: @organization,
      email: "manager-jobs@example.com",
      role: "manager"
    )

    @owner = create_user(
      organization: @organization,
      email: "owner-jobs@example.com",
      role: "owner"
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

    @site = Site.create!(
      organization: @organization,
      customer: @customer,
      name: "Job Test Site"
    )

    @other_customer = Customer.create!(
      organization: @other_organization,
      customer_type: "individual",
      first_name: "Other",
      last_name: "Customer",
      email: "other-customer-jobs@example.com"
    )

    @other_site = Site.create!(
      organization: @other_organization,
      customer: @other_customer,
      name: "Other Job Site"
    )

    @team = Team.create!(
      organization: @organization,
      code: "TEAM-JOB",
      name: "Job Team"
    )

    @vehicle = Vehicle.create!(
      organization: @organization,
      name: "Job Vehicle",
      registration_number: "JOB-001"
    )

    @other_team = Team.create!(
      organization: @other_organization,
      code: "OTHER-JOB",
      name: "Other Job Team"
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
      team: @team,
      vehicle: @vehicle,
      title: "Garden Maintenance",
      job_type: "maintenance",
      status: "planned",
      priority: "normal",
      scheduled_date: Date.current
    )

    @other_job = Job.create!(
      organization: @other_organization,
      customer: @other_customer,
      site: @other_site,
      team: @other_team,
      vehicle: @other_vehicle,
      title: "Other Organization Job",
      job_type: "maintenance",
      status: "planned",
      priority: "normal",
      scheduled_date: Date.current
    )

    @manager_token = JwtService.encode(@manager)
    @owner_token = JwtService.encode(@owner)
    @field_worker_token = JwtService.encode(@field_worker)
    @member_token = JwtService.encode(@member)
    @other_manager_token = JwtService.encode(@other_manager)

    JobAssignment.create!(
      organization: @organization,
      job: @job,
      user: @field_worker,
      assignment_type: "worker",
      role: "worker",
      active: true
    )
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
  end

  test "index can filter jobs by date" do
    other_date_job = Job.create!(
      organization: @organization,
      customer: @customer,
      site: @site,
      title: "Future Job",
      job_type: "maintenance",
      status: "planned",
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
    assert_equal other_date_job.id, body.first["id"]
  end

  test "show returns a job from the same organization" do
    get "/api/v1/jobs/#{@job.id}",
        headers: {
          "Authorization" => "Bearer #{@manager_token}"
        }

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal @job.id, body["id"]
  end

  test "show cannot access a job from another organization" do
    get "/api/v1/jobs/#{@other_job.id}",
        headers: {
          "Authorization" => "Bearer #{@manager_token}"
        }

    assert_response :not_found
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
               title: "New Garden Job",
               job_type: "maintenance",
               status: "planned",
               priority: "normal",
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

  test "member cannot create a job" do
    assert_no_difference("Job.count") do
      post "/api/v1/jobs",
           params: {
             job: {
               customer_id: @customer.id,
               site_id: @site.id,
               title: "Unauthorized Job",
               job_type: "maintenance"
             }
           },
           headers: {
             "Authorization" => "Bearer #{@member_token}"
           }
    end

    assert_response :forbidden
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

  test "owner can destroy a job" do
    assert_difference("Job.count", -1) do
      delete "/api/v1/jobs/#{@job.id}",
             headers: {
               "Authorization" => "Bearer #{@owner_token}"
             }
    end

    assert_response :no_content
  end

  test "field worker cannot destroy a job" do
    assert_no_difference("Job.count") do
      delete "/api/v1/jobs/#{@job.id}",
             headers: {
               "Authorization" => "Bearer #{@field_worker_token}"
             }
    end

    assert_response :forbidden
  end

  test "cannot create a job with customer from another organization" do
    assert_no_difference("Job.count") do
      post "/api/v1/jobs",
           params: {
             job: {
               customer_id: @other_customer.id,
               site_id: @site.id,
               title: "Cross Organization Job",
               job_type: "maintenance"
             }
           },
           headers: {
             "Authorization" => "Bearer #{@manager_token}"
           }
    end

    assert_response :forbidden
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
               job_type: "maintenance"
             }
           },
           headers: {
             "Authorization" => "Bearer #{@manager_token}"
           }
    end

    assert_response :forbidden
  end

  
end