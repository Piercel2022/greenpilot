require "test_helper"

class JobReportsApiTest < ActionDispatch::IntegrationTest
  # ============================================================
  # AUTHENTICATION
  # ============================================================

  test "index requires authentication" do
    get "/api/v1/job_reports"

    assert_response :unauthorized
  end

  test "index rejects invalid token" do
    get "/api/v1/job_reports",
        headers: {
          "Authorization" => "Bearer invalid-token"
        }

    assert_response :unauthorized
  end

  # ============================================================
  # INDEX
  # ============================================================

  test "authenticated user can list job reports" do
    user = users(:member_a)

    get "/api/v1/job_reports",
        headers: auth_headers(user)

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal 1, body.length
    assert_equal job_reports(:job_report_a).id, body.first["id"]
  end

  test "index only returns job reports from user's organization" do
    user = users(:member_a)

    get "/api/v1/job_reports",
        headers: auth_headers(user)

    assert_response :success

    body = JSON.parse(response.body)

    report_ids = body.map { |report| report["id"] }

    assert_includes report_ids, job_reports(:job_report_a).id
    assert_not_includes report_ids, job_reports(:job_report_b).id
  end

  # ============================================================
  # SHOW
  # ============================================================

  test "user can view job report from same organization" do
    user = users(:member_a)
    report = job_reports(:job_report_a)

    get "/api/v1/job_reports/#{report.id}",
        headers: auth_headers(user)

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal report.id, body["id"]
    assert_equal report.job_id, body["job_id"]
  end

  test "user cannot access job report from another organization" do
    user = users(:member_a)
    report = job_reports(:job_report_b)

    get "/api/v1/job_reports/#{report.id}",
        headers: auth_headers(user)

    assert_response :not_found
  end

  test "show returns not found for unknown job report" do
    user = users(:member_a)

    get "/api/v1/job_reports/#{SecureRandom.uuid}",
        headers: auth_headers(user)

    assert_response :not_found
  end

  # ============================================================
  # CREATE
  # ============================================================

  test "owner can create job report" do
    user = users(:owner_a)

    assert_difference("JobReport.count", 1) do
      post "/api/v1/job_reports",
           params: {
             job_report: {
               job_id: jobs(:job_a).id,
               summary: "Owner report",
               work_performed: "Garden maintenance completed",
               observations: "Everything went well"
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :created

    body = JSON.parse(response.body)

    assert_equal jobs(:job_a).id, body["job_id"]
    assert_equal "Owner report", body["summary"]
  end

  test "admin can create job report" do
    user = users(:admin_a)

    assert_difference("JobReport.count", 1) do
      post "/api/v1/job_reports",
           params: {
             job_report: {
               job_id: jobs(:job_a).id,
               summary: "Admin report"
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :created
  end

  test "manager can create job report" do
    user = users(:manager_a)

    assert_difference("JobReport.count", 1) do
      post "/api/v1/job_reports",
           params: {
             job_report: {
               job_id: jobs(:job_a).id,
               summary: "Manager report"
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :created
  end

  test "member cannot create job report" do
    user = users(:member_a)

    assert_no_difference("JobReport.count") do
      post "/api/v1/job_reports",
           params: {
             job_report: {
               job_id: jobs(:job_a).id,
               summary: "Unauthorized report"
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :forbidden
  end

  test "field worker cannot create job report" do
    user = users(:field_worker_a)

    assert_no_difference("JobReport.count") do
      post "/api/v1/job_reports",
           params: {
             job_report: {
               job_id: jobs(:job_a).id,
               summary: "Unauthorized report"
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :forbidden
  end

  test "accountant cannot create job report" do
    user = users(:accountant_a)

    assert_no_difference("JobReport.count") do
      post "/api/v1/job_reports",
           params: {
             job_report: {
               job_id: jobs(:job_a).id,
               summary: "Unauthorized report"
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :forbidden
  end

  # ============================================================
  # CREATE — TENANT ISOLATION
  # ============================================================

  test "create rejects job from another organization" do
    user = users(:manager_a)

    assert_no_difference("JobReport.count") do
      post "/api/v1/job_reports",
           params: {
             job_report: {
               job_id: jobs(:job_b).id,
               summary: "Cross organization report"
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :forbidden
  end

  # ============================================================
  # CREATE — VALIDATION
  # ============================================================

  test "create rejects missing job" do
    user = users(:manager_a)

    assert_no_difference("JobReport.count") do
      post "/api/v1/job_reports",
           params: {
             job_report: {
               summary: "Report without job"
             }
           },
           headers: auth_headers(user),
           as: :json
    end

    assert_response :unprocessable_entity
  end

  # ============================================================
  # UPDATE
  # ============================================================

  test "owner can update job report" do
    user = users(:owner_a)
    report = job_reports(:job_report_a)

    patch "/api/v1/job_reports/#{report.id}",
          params: {
            job_report: {
              summary: "Updated report"
            }
          },
          headers: auth_headers(user),
          as: :json

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal "Updated report", body["summary"]
  end

  test "admin can update job report" do
    user = users(:admin_a)
    report = job_reports(:job_report_a)

    patch "/api/v1/job_reports/#{report.id}",
          params: {
            job_report: {
              summary: "Updated by admin"
            }
          },
          headers: auth_headers(user),
          as: :json

    assert_response :success
  end

  test "manager can update job report" do
    user = users(:manager_a)
    report = job_reports(:job_report_a)

    patch "/api/v1/job_reports/#{report.id}",
          params: {
            job_report: {
              summary: "Updated by manager"
            }
          },
          headers: auth_headers(user),
          as: :json

    assert_response :success
  end

  test "member cannot update job report" do
    user = users(:member_a)
    report = job_reports(:job_report_a)

    patch "/api/v1/job_reports/#{report.id}",
          params: {
            job_report: {
              summary: "Unauthorized update"
            }
          },
          headers: auth_headers(user),
          as: :json

    assert_response :forbidden
  end

  test "field worker cannot update job report" do
    user = users(:field_worker_a)
    report = job_reports(:job_report_a)

    patch "/api/v1/job_reports/#{report.id}",
          params: {
            job_report: {
              summary: "Unauthorized update"
            }
          },
          headers: auth_headers(user),
          as: :json

    assert_response :forbidden
  end

  test "accountant cannot update job report" do
    user = users(:accountant_a)
    report = job_reports(:job_report_a)

    patch "/api/v1/job_reports/#{report.id}",
          params: {
            job_report: {
              summary: "Unauthorized update"
            }
          },
          headers: auth_headers(user),
          as: :json

    assert_response :forbidden
  end

  test "manager cannot update job report from another organization" do
    user = users(:manager_a)
    report = job_reports(:job_report_b)

    patch "/api/v1/job_reports/#{report.id}",
          params: {
            job_report: {
              summary: "Cross organization update"
            }
          },
          headers: auth_headers(user),
          as: :json

    assert_response :not_found
  end

  # ============================================================
  # DESTROY
  # ============================================================

  test "owner can destroy job report" do
    user = users(:owner_a)
    report = job_reports(:job_report_a)

    assert_difference("JobReport.count", -1) do
      delete "/api/v1/job_reports/#{report.id}",
             headers: auth_headers(user)
    end

    assert_response :no_content
  end

  test "admin can destroy job report" do
    user = users(:admin_a)
    report = job_reports(:job_report_a)

    assert_difference("JobReport.count", -1) do
      delete "/api/v1/job_reports/#{report.id}",
             headers: auth_headers(user)
    end

    assert_response :no_content
  end

  test "manager cannot destroy job report" do
    user = users(:manager_a)
    report = job_reports(:job_report_a)

    assert_no_difference("JobReport.count") do
      delete "/api/v1/job_reports/#{report.id}",
             headers: auth_headers(user)
    end

    assert_response :forbidden
  end

  test "member cannot destroy job report" do
    user = users(:member_a)
    report = job_reports(:job_report_a)

    assert_no_difference("JobReport.count") do
      delete "/api/v1/job_reports/#{report.id}",
             headers: auth_headers(user)
    end

    assert_response :forbidden
  end

  test "field worker cannot destroy job report" do
    user = users(:field_worker_a)
    report = job_reports(:job_report_a)

    assert_no_difference("JobReport.count") do
      delete "/api/v1/job_reports/#{report.id}",
             headers: auth_headers(user)
    end

    assert_response :forbidden
  end

  test "accountant cannot destroy job report" do
    user = users(:accountant_a)
    report = job_reports(:job_report_a)

    assert_no_difference("JobReport.count") do
      delete "/api/v1/job_reports/#{report.id}",
             headers: auth_headers(user)
    end

    assert_response :forbidden
  end

  test "cannot destroy job report from another organization" do
    user = users(:owner_a)
    report = job_reports(:job_report_b)

    assert_no_difference("JobReport.count") do
      delete "/api/v1/job_reports/#{report.id}",
             headers: auth_headers(user)
    end

    assert_response :not_found
  end
end