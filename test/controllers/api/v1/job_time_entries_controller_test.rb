require "test_helper"

class Api::V1::JobTimeEntriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organization = Organization.create!(
      name: "GreenPilot Time Entries Test",
      slug: "greenpilot-time-entries-test"
    )

    @other_organization = Organization.create!(
      name: "Other Organization",
      slug: "other-organization-time-entries-test"
    )

    @manager = create_user(
      organization: @organization,
      email: "manager-time@example.com",
      role: "manager"
    )

    @owner = create_user(
      organization: @organization,
      email: "owner-time@example.com",
      role: "owner"
    )

    @field_worker = create_user(
      organization: @organization,
      email: "worker-time@example.com",
      role: "field_worker"
    )

    @unassigned_worker = create_user(
      organization: @organization,
      email: "unassigned-time@example.com",
      role: "field_worker"
    )

    @member = create_user(
      organization: @organization,
      email: "member-time@example.com",
      role: "member"
    )

    @other_manager = create_user(
      organization: @other_organization,
      email: "other-manager-time@example.com",
      role: "manager"
    )

    @other_worker = create_user(
      organization: @other_organization,
      email: "other-worker-time@example.com",
      role: "field_worker"
    )

    @customer = Customer.create!(
      organization: @organization,
      customer_type: "individual",
      first_name: "John",
      last_name: "Customer",
      email: "john-time@example.com"
    )

    @site = Site.create!(
      organization: @organization,
      customer: @customer,
      name: "Time Entry Site"
    )

    @other_customer = Customer.create!(
      organization: @other_organization,
      customer_type: "individual",
      first_name: "Other",
      last_name: "Customer",
      email: "other-time@example.com"
    )

    @other_site = Site.create!(
      organization: @other_organization,
      customer: @other_customer,
      name: "Other Time Site"
    )

    @job = Job.create!(
      organization: @organization,
      customer: @customer,
      site: @site,
      title: "Garden Maintenance",
      job_type: "maintenance",
      status: "in_progress",
      priority: "normal",
      scheduled_date: Date.current
    )

    @other_job = Job.create!(
      organization: @other_organization,
      customer: @other_customer,
      site: @other_site,
      title: "Other Organization Job",
      job_type: "maintenance",
      status: "in_progress",
      priority: "normal",
      scheduled_date: Date.current
    )

    @assignment = JobAssignment.create!(
      organization: @organization,
      job: @job,
      user: @field_worker,
      assignment_type: "primary",
      role: "worker",
      active: true
    )

    @other_assignment = JobAssignment.create!(
      organization: @other_organization,
      job: @other_job,
      user: @other_worker,
      assignment_type: "primary",
      role: "worker",
      active: true
    )

    @time_entry = JobTimeEntry.create!(
      organization: @organization,
      job: @job,
      user: @field_worker,
      entry_type: "work",
      started_at: Time.zone.parse("2026-08-24 08:00:00"),
      ended_at: Time.zone.parse("2026-08-24 10:00:00"),
      duration_minutes: 120,
      notes: "Morning work"
    )

    @other_time_entry = JobTimeEntry.create!(
      organization: @other_organization,
      job: @other_job,
      user: @other_worker,
      entry_type: "work",
      started_at: Time.zone.parse("2026-08-24 08:00:00"),
      ended_at: Time.zone.parse("2026-08-24 10:00:00"),
      duration_minutes: 120
    )

    @manager_token = JwtService.encode(@manager)
    @owner_token = JwtService.encode(@owner)
    @field_worker_token = JwtService.encode(@field_worker)
    @unassigned_worker_token = JwtService.encode(@unassigned_worker)
    @member_token = JwtService.encode(@member)
    @other_manager_token = JwtService.encode(@other_manager)
  end

  test "index requires authentication" do
    get "/api/v1/job_time_entries"

    assert_response :unauthorized
  end

  test "index returns time entries from the current organization" do
    get "/api/v1/job_time_entries",
        headers: {
          "Authorization" => "Bearer #{@manager_token}"
        }

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal 1, body.length
    assert_equal @time_entry.id, body.first["id"]
  end

  test "field worker index returns only entries from assigned jobs" do
    get "/api/v1/job_time_entries",
        headers: {
          "Authorization" => "Bearer #{@field_worker_token}"
        }

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal 1, body.length
    assert_equal @time_entry.id, body.first["id"]
  end

  test "show returns a time entry from the same organization" do
    get "/api/v1/job_time_entries/#{@time_entry.id}",
        headers: {
          "Authorization" => "Bearer #{@manager_token}"
        }

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal @time_entry.id, body["id"]
  end

  test "show cannot access a time entry from another organization" do
    get "/api/v1/job_time_entries/#{@other_time_entry.id}",
        headers: {
          "Authorization" => "Bearer #{@manager_token}"
        }

    assert_response :not_found
  end

  test "manager can create a time entry" do
    assert_difference("JobTimeEntry.count", 1) do
      post "/api/v1/job_time_entries",
           params: {
             job_time_entry: {
               job_id: @job.id,
               user_id: @field_worker.id,
               entry_type: "work",
               started_at: "2026-08-24T11:00:00+02:00",
               ended_at: "2026-08-24T12:00:00+02:00",
               duration_minutes: 60,
               notes: "Additional work"
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
    assert_equal @field_worker.id, body["user_id"]
  end

  test "assigned field worker can create a time entry" do
    assert_difference("JobTimeEntry.count", 1) do
      post "/api/v1/job_time_entries",
           params: {
             job_time_entry: {
               job_id: @job.id,
               user_id: @field_worker.id,
               entry_type: "work",
               started_at: "2026-08-24T13:00:00+02:00",
               ended_at: "2026-08-24T14:00:00+02:00",
               duration_minutes: 60
             }
           },
           headers: {
             "Authorization" => "Bearer #{@field_worker_token}"
           }
    end

    assert_response :created
  end

  test "unassigned field worker cannot create a time entry" do
    assert_no_difference("JobTimeEntry.count") do
      post "/api/v1/job_time_entries",
           params: {
             job_time_entry: {
               job_id: @job.id,
               user_id: @unassigned_worker.id,
               entry_type: "work",
               started_at: "2026-08-24T13:00:00+02:00",
               duration_minutes: 60
             }
           },
           headers: {
             "Authorization" => "Bearer #{@unassigned_worker_token}"
           }
    end

    assert_response :forbidden
  end

  test "member cannot create a time entry" do
    assert_no_difference("JobTimeEntry.count") do
      post "/api/v1/job_time_entries",
           params: {
             job_time_entry: {
               job_id: @job.id,
               user_id: @field_worker.id,
               entry_type: "work",
               started_at: "2026-08-24T13:00:00+02:00",
               duration_minutes: 60
             }
           },
           headers: {
             "Authorization" => "Bearer #{@member_token}"
           }
    end

    assert_response :forbidden
  end

  test "field worker can update their own time entry" do
    patch "/api/v1/job_time_entries/#{@time_entry.id}",
          params: {
            job_time_entry: {
              duration_minutes: 150,
              notes: "Updated work"
            }
          },
          headers: {
            "Authorization" => "Bearer #{@field_worker_token}"
          }

    assert_response :success

    entry = @time_entry.reload

    assert_equal 150, entry.duration_minutes
    assert_equal "Updated work", entry.notes
  end

  test "field worker cannot update another user's time entry" do
    other_entry = JobTimeEntry.create!(
      organization: @organization,
      job: @job,
      user: @manager,
      entry_type: "work",
      started_at: Time.zone.parse("2026-08-24 15:00:00"),
      duration_minutes: 60
    )

    patch "/api/v1/job_time_entries/#{other_entry.id}",
          params: {
            job_time_entry: {
              duration_minutes: 90
            }
          },
          headers: {
            "Authorization" => "Bearer #{@field_worker_token}"
          }

    assert_response :forbidden
    assert_equal 60, other_entry.reload.duration_minutes
  end

  test "manager can update a time entry" do
    patch "/api/v1/job_time_entries/#{@time_entry.id}",
          params: {
            job_time_entry: {
              duration_minutes: 180,
              notes: "Manager correction"
            }
          },
          headers: {
            "Authorization" => "Bearer #{@manager_token}"
          }

    assert_response :success

    entry = @time_entry.reload

    assert_equal 180, entry.duration_minutes
    assert_equal "Manager correction", entry.notes
  end

  test "member cannot update a time entry" do
    patch "/api/v1/job_time_entries/#{@time_entry.id}",
          params: {
            job_time_entry: {
              duration_minutes: 90
            }
          },
          headers: {
            "Authorization" => "Bearer #{@member_token}"
          }

    assert_response :forbidden
    assert_equal 120, @time_entry.reload.duration_minutes
  end

  test "manager can destroy a time entry" do
    assert_difference("JobTimeEntry.count", -1) do
      delete "/api/v1/job_time_entries/#{@time_entry.id}",
             headers: {
               "Authorization" => "Bearer #{@manager_token}"
             }
    end

    assert_response :no_content
  end

  test "field worker cannot destroy a time entry" do
    assert_no_difference("JobTimeEntry.count") do
      delete "/api/v1/job_time_entries/#{@time_entry.id}",
             headers: {
               "Authorization" => "Bearer #{@field_worker_token}"
             }
    end

    assert_response :forbidden
  end

  test "cannot create a time entry with a job from another organization" do
    assert_no_difference("JobTimeEntry.count") do
      post "/api/v1/job_time_entries",
           params: {
             job_time_entry: {
               job_id: @other_job.id,
               user_id: @field_worker.id,
               entry_type: "work",
               started_at: "2026-08-24T13:00:00+02:00",
               duration_minutes: 60
             }
           },
           headers: {
             "Authorization" => "Bearer #{@manager_token}"
           }
    end

    assert_response :forbidden
  end

  test "cannot create a time entry with a user from another organization" do
    assert_no_difference("JobTimeEntry.count") do
      post "/api/v1/job_time_entries",
           params: {
             job_time_entry: {
               job_id: @job.id,
               user_id: @other_worker.id,
               entry_type: "work",
               started_at: "2026-08-24T13:00:00+02:00",
               duration_minutes: 60
             }
           },
           headers: {
             "Authorization" => "Bearer #{@manager_token}"
           }
    end

    assert_response :forbidden
  end
end