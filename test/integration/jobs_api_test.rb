require "test_helper"

class JobsApiTest < ActionDispatch::IntegrationTest
  setup do
    @organization = organizations(:organization_a)
    @other_organization = organizations(:organization_b)

    @owner = users(:owner_a)
    @manager = users(:manager_a)
    @member = users(:member_a)
    @field_worker = users(:field_worker_a)

    @job = jobs(:job_a)
    @other_job = jobs(:job_b)

    @owner_token = JwtService.encode(@owner)
    @manager_token = JwtService.encode(@manager)
    @member_token = JwtService.encode(@member)
    @field_worker_token = JwtService.encode(@field_worker)
  end

  test "index returns jobs from current organization only" do
    get "/api/v1/jobs",
        headers: {
          "Authorization" => "Bearer #{@manager_token}"
        }

    assert_response :success

    body = JSON.parse(response.body)

    assert body.any? { |job| job["id"] == @job.id }
    assert body.none? { |job| job["id"] == @other_job.id }
    assert body.all? { |job| job["organization_id"] == @organization.id }
  end

  test "index requires authentication" do
    get "/api/v1/jobs"

    assert_response :unauthorized
  end

  test "show returns a job from current organization" do
    get "/api/v1/jobs/#{@job.id}",
        headers: {
          "Authorization" => "Bearer #{@manager_token}"
        }

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal @job.id, body["id"]
    assert_equal @organization.id, body["organization_id"]
  end

  test "show cannot access another organization's job" do
    get "/api/v1/jobs/#{@other_job.id}",
        headers: {
          "Authorization" => "Bearer #{@manager_token}"
        }

    assert_response :not_found
  end

  test "manager can create a job" do
    customer = customers(:customer_a)
    site = sites(:site_a)

    assert_difference("Job.count", 1) do
      post "/api/v1/jobs",
           params: {
             job: {
               customer_id: customer.id,
               site_id: site.id,
               title: "Integration Job",
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

    assert_equal "Integration Job", body["title"]
    assert_equal @organization.id, body["organization_id"]
    assert_equal customer.id, body["customer_id"]
    assert_equal site.id, body["site_id"]
  end

  test "member cannot create a job" do
    assert_no_difference("Job.count") do
      post "/api/v1/jobs",
           params: {
             job: {
               customer_id: customers(:customer_a).id,
               site_id: sites(:site_a).id,
               title: "Unauthorized Job",
               job_type: "maintenance",
               status: "planned",
               priority: "normal",
               weather_risk: "unknown"
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
              title: "Updated Integration Job"
            }
          },
          headers: {
            "Authorization" => "Bearer #{@manager_token}"
          }

    assert_response :success

    assert_equal "Updated Integration Job", @job.reload.title
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

  test "member cannot update a job" do
    original_title = @job.title

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

    assert_equal original_title, @job.reload.title
  end

  test "manager cannot update another organization's job" do
  original_title = @other_job.title

  patch "/api/v1/jobs/#{@other_job.id}",
        params: {
          job: {
            title: "Cross Organization Update"
          }
        },
        headers: {
          "Authorization" => "Bearer #{@manager_token}"
        }

  assert_response :not_found

  assert_equal original_title, @other_job.reload.title
  end

  test "owner can destroy a job" do
    job = Job.create!(
      organization: @organization,
      customer: customers(:customer_a),
      site: sites(:site_a),
      title: "Integration Delete Job",
      job_type: "maintenance",
      status: "planned",
      priority: "normal",
      weather_risk: "unknown"
    )

    assert_difference("Job.count", -1) do
      delete "/api/v1/jobs/#{job.id}",
             headers: {
               "Authorization" => "Bearer #{@owner_token}"
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

  test "index filters jobs by date" do
    future_date = Date.current + 10.days

    future_job = Job.create!(
      organization: @organization,
      customer: customers(:customer_a),
      site: sites(:site_a),
      title: "Future Integration Job",
      job_type: "maintenance",
      status: "planned",
      priority: "normal",
      weather_risk: "unknown",
      scheduled_date: future_date
    )

    get "/api/v1/jobs",
        params: {
          date: future_date.to_s
        },
        headers: {
          "Authorization" => "Bearer #{@manager_token}"
        }

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal [future_job.id], body.map { |job| job["id"] }
  end

  test "index filters jobs by status" do
    completed_job = Job.create!(
      organization: @organization,
      customer: customers(:customer_a),
      site: sites(:site_a),
      title: "Completed Integration Job",
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

    assert_equal [completed_job.id], body.map { |job| job["id"] }
  end

  test "index filters jobs by priority" do
    urgent_job = Job.create!(
      organization: @organization,
      customer: customers(:customer_a),
      site: sites(:site_a),
      title: "Urgent Integration Job",
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

    assert_equal [urgent_job.id], body.map { |job| job["id"] }
  end

  test "cannot create a job with a customer from another organization" do
    assert_no_difference("Job.count") do
      post "/api/v1/jobs",
           params: {
             job: {
               customer_id: customers(:customer_b).id,
               site_id: sites(:site_a).id,
               title: "Cross Organization Job",
               job_type: "maintenance",
               status: "planned",
               priority: "normal",
               weather_risk: "unknown"
             }
           },
           headers: {
             "Authorization" => "Bearer #{@manager_token}"
           }
    end

    assert_response :unprocessable_entity
  end

  test "cannot create a job with a site from another organization" do
    assert_no_difference("Job.count") do
      post "/api/v1/jobs",
           params: {
             job: {
               customer_id: customers(:customer_a).id,
               site_id: sites(:site_b).id,
               title: "Cross Organization Site Job",
               job_type: "maintenance",
               status: "planned",
               priority: "normal",
               weather_risk: "unknown"
             }
           },
           headers: {
             "Authorization" => "Bearer #{@manager_token}"
           }
    end

    assert_response :unprocessable_entity
  end

  test "cannot create a job with a site belonging to another customer" do
    assert_no_difference("Job.count") do
      post "/api/v1/jobs",
           params: {
             job: {
               customer_id: customers(:customer_a).id,
               site_id: sites(:site_b).id,
               title: "Cross Customer Site Job",
               job_type: "maintenance",
               status: "planned",
               priority: "normal",
               weather_risk: "unknown"
             }
           },
           headers: {
             "Authorization" => "Bearer #{@manager_token}"
           }
    end

    assert_response :unprocessable_entity
  end

  test "create ignores organization_id from request parameters" do
    post "/api/v1/jobs",
         params: {
           job: {
             organization_id: @other_organization.id,
             customer_id: customers(:customer_a).id,
             site_id: sites(:site_a).id,
             title: "Tenant Isolation Job",
             job_type: "maintenance",
             status: "planned",
             priority: "normal",
             weather_risk: "unknown"
           }
         },
         headers: {
           "Authorization" => "Bearer #{@manager_token}"
         }

    assert_response :created

    job = Job.order(created_at: :desc).first

    assert_equal @organization.id, job.organization_id
    assert_not_equal @other_organization.id, job.organization_id
  end
end