require "test_helper"

class JobAssignmentsApiTest < ActionDispatch::IntegrationTest
  setup do
    @organization = Organization.create!(
      name: "GreenPilot Job Assignments Integration",
      slug: "greenpilot-job-assignments-integration"
    )

    @other_organization = Organization.create!(
      name: "Other Organization",
      slug: "other-organization-job-assignments"
    )

    @manager = create_user(
      organization: @organization,
      email: "manager-job-assignments@example.com",
      role: "manager"
    )

    @member = create_user(
      organization: @organization,
      email: "member-job-assignments@example.com",
      role: "member"
    )

    @field_worker = create_user(
      organization: @organization,
      email: "worker-job-assignments@example.com",
      role: "field_worker"
    )

    @other_manager = create_user(
      organization: @other_organization,
      email: "other-manager-job-assignments@example.com",
      role: "manager"
    )

    @other_field_worker = create_user(
      organization: @other_organization,
      email: "other-worker-job-assignments@example.com",
      role: "field_worker"
    )

    @customer = Customer.create!(
      organization: @organization,
      customer_type: "individual",
      first_name: "John",
      last_name: "Customer",
      email: "john-job-assignments@example.com"
    )

    @site = Site.create!(
      organization: @organization,
      customer: @customer,
      name: "Assignment Site"
    )

    @other_customer = Customer.create!(
      organization: @other_organization,
      customer_type: "individual",
      first_name: "Other",
      last_name: "Customer",
      email: "other-job-assignments@example.com"
    )

    @other_site = Site.create!(
      organization: @other_organization,
      customer: @other_customer,
      name: "Other Assignment Site"
    )

    @job = Job.create!(
      organization: @organization,
      customer: @customer,
      site: @site,
      title: "Assignment Job",
      job_type: "maintenance",
      status: "planned",
      priority: "normal",
      scheduled_date: Date.current
    )

    @other_job = Job.create!(
      organization: @other_organization,
      customer: @other_customer,
      site: @other_site,
      title: "Other Organization Job",
      job_type: "maintenance",
      status: "planned",
      priority: "normal",
      scheduled_date: Date.current
    )

    @assignment = JobAssignment.create!(
      organization: @organization,
      job: @job,
      user: @field_worker,
      assignment_type: "primary",
      role: "worker",
      active: true,
      assigned_at: Time.zone.parse("2026-08-22 09:00:00"),
      accepted_at: Time.zone.parse("2026-08-22 09:15:00")
    )

    @other_assignment = JobAssignment.create!(
      organization: @other_organization,
      job: @other_job,
      user: @other_field_worker,
      assignment_type: "primary",
      role: "worker",
      active: true,
      assigned_at: Time.zone.parse("2026-08-22 09:00:00"),
      accepted_at: Time.zone.parse("2026-08-22 09:15:00")
    )

    @manager_token = JwtService.encode(@manager)
    @member_token = JwtService.encode(@member)
    @other_manager_token = JwtService.encode(@other_manager)
  end

  test "index requires authentication" do
    get "/api/v1/job_assignments"

    assert_response :unauthorized
  end

  test "index returns only assignments from current organization" do
    get "/api/v1/job_assignments",
        headers: {
          "Authorization" => "Bearer #{@manager_token}"
        }

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal 1, body.length
    assert_equal @assignment.id, body.first["id"]
    assert_equal @organization.id, body.first["organization_id"]
  end

  test "show returns assignment from same organization" do
    get "/api/v1/job_assignments/#{@assignment.id}",
        headers: {
          "Authorization" => "Bearer #{@manager_token}"
        }

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal @assignment.id, body["id"]
    assert_equal @organization.id, body["organization_id"]
  end

  test "show cannot access assignment from another organization" do
    get "/api/v1/job_assignments/#{@other_assignment.id}",
        headers: {
          "Authorization" => "Bearer #{@manager_token}"
        }

    assert_response :not_found
  end

  test "manager can create assignment" do
    new_worker = create_user(
      organization: @organization,
      email: "new-worker-job-assignments@example.com",
      role: "field_worker"
    )

    assert_difference("JobAssignment.count", 1) do
      post "/api/v1/job_assignments",
           params: {
             job_assignment: {
               job_id: @job.id,
               user_id: new_worker.id,
               assignment_type: "secondary",
               role: "worker",
               active: true
             }
           },
           headers: {
             "Authorization" => "Bearer #{@manager_token}"
           }
    end

    assert_response :created

    body = JSON.parse(response.body)

    assert_equal @organization.id, body["organization_id"]
    assert_equal @job.id, body["job_id"]
    assert_equal new_worker.id, body["user_id"]
    assert_equal "secondary", body["assignment_type"]
    assert_equal "worker", body["role"]
  end

  test "member cannot create assignment" do
    new_worker = create_user(
      organization: @organization,
      email: "member-new-worker-job-assignments@example.com",
      role: "field_worker"
    )

    assert_no_difference("JobAssignment.count") do
      post "/api/v1/job_assignments",
           params: {
             job_assignment: {
               job_id: @job.id,
               user_id: new_worker.id,
               assignment_type: "secondary",
               role: "worker"
             }
           },
           headers: {
             "Authorization" => "Bearer #{@member_token}"
           }
    end

    assert_response :forbidden
  end

  test "manager cannot create assignment with foreign job" do
    new_worker = create_user(
      organization: @organization,
      email: "foreign-job-worker@example.com",
      role: "field_worker"
    )

    assert_no_difference("JobAssignment.count") do
      post "/api/v1/job_assignments",
           params: {
             job_assignment: {
               job_id: @other_job.id,
               user_id: new_worker.id,
               assignment_type: "secondary",
               role: "worker"
             }
           },
           headers: {
             "Authorization" => "Bearer #{@manager_token}"
           }
    end

    assert_response :forbidden
  end

  test "manager cannot create assignment with foreign user" do
    assert_no_difference("JobAssignment.count") do
      post "/api/v1/job_assignments",
           params: {
             job_assignment: {
               job_id: @job.id,
               user_id: @other_field_worker.id,
               assignment_type: "secondary",
               role: "worker"
             }
           },
           headers: {
             "Authorization" => "Bearer #{@manager_token}"
           }
    end

    assert_response :forbidden
  end

  test "manager cannot create assignment for foreign organization" do
    assert_no_difference("JobAssignment.count") do
      post "/api/v1/job_assignments",
           params: {
             job_assignment: {
               job_id: @other_job.id,
               user_id: @other_field_worker.id,
               assignment_type: "secondary",
               role: "worker"
             }
           },
           headers: {
             "Authorization" => "Bearer #{@manager_token}"
           }
    end

    assert_response :forbidden
  end

  test "cannot create duplicate assignment for same user and job" do
    assert_no_difference("JobAssignment.count") do
      post "/api/v1/job_assignments",
           params: {
             job_assignment: {
               job_id: @job.id,
               user_id: @field_worker.id,
               assignment_type: "secondary",
               role: "worker"
             }
           },
           headers: {
             "Authorization" => "Bearer #{@manager_token}"
           }
    end

    assert_response :unprocessable_entity
  end

  test "manager can update assignment" do
    patch "/api/v1/job_assignments/#{@assignment.id}",
          params: {
            job_assignment: {
              active: false,
              notes: "Assignment completed"
            }
          },
          headers: {
            "Authorization" => "Bearer #{@manager_token}"
          }

    assert_response :success

    assignment = @assignment.reload

    assert_equal false, assignment.active
    assert_equal "Assignment completed", assignment.notes
  end

  test "member cannot update assignment" do
    patch "/api/v1/job_assignments/#{@assignment.id}",
          params: {
            job_assignment: {
              active: false
            }
          },
          headers: {
            "Authorization" => "Bearer #{@member_token}"
          }

    assert_response :forbidden

    assert_equal true, @assignment.reload.active
  end

  test "manager cannot update assignment from another organization" do
    patch "/api/v1/job_assignments/#{@other_assignment.id}",
          params: {
            job_assignment: {
              active: false
            }
          },
          headers: {
            "Authorization" => "Bearer #{@manager_token}"
          }

    assert_response :not_found

    assert_equal true, @other_assignment.reload.active
  end

  test "manager can destroy assignment" do
    assert_difference("JobAssignment.count", -1) do
      delete "/api/v1/job_assignments/#{@assignment.id}",
             headers: {
               "Authorization" => "Bearer #{@manager_token}"
             }
    end

    assert_response :no_content
  end

  test "member cannot destroy assignment" do
    assert_no_difference("JobAssignment.count") do
      delete "/api/v1/job_assignments/#{@assignment.id}",
             headers: {
               "Authorization" => "Bearer #{@member_token}"
             }
    end

    assert_response :forbidden
  end

  test "manager cannot destroy assignment from another organization" do
    assert_no_difference("JobAssignment.count") do
      delete "/api/v1/job_assignments/#{@other_assignment.id}",
             headers: {
               "Authorization" => "Bearer #{@manager_token}"
             }
    end

    assert_response :not_found

    assert JobAssignment.exists?(@other_assignment.id)
  end

  test "show returns not found for unknown assignment" do
    get "/api/v1/job_assignments/#{SecureRandom.uuid}",
        headers: {
          "Authorization" => "Bearer #{@manager_token}"
        }

    assert_response :not_found
  end
end