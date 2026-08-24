require "test_helper"

class Api::V1::JobReportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organization = Organization.create!(
      name: "GreenPilot Reports Test",
      slug: "greenpilot-reports-test"
    )

    @other_organization = Organization.create!(
      name: "Other Reports Organization",
      slug: "other-reports-organization-test"
    )

    @manager = create_user(
      organization: @organization,
      email: "manager-reports@example.com",
      role: "manager"
    )

    @owner = create_user(
      organization: @organization,
      email: "owner-reports@example.com",
      role: "owner"
    )

    @member = create_user(
      organization: @organization,
      email: "member-reports@example.com",
      role: "member"
    )

    @other_manager = create_user(
      organization: @other_organization,
      email: "other-manager-reports@example.com",
      role: "manager"
    )

    @customer = Customer.create!(
      organization: @organization,
      customer_type: "individual",
      first_name: "John",
      last_name: "Customer",
      email: "john-reports@example.com"
    )

    @site = Site.create!(
      organization: @organization,
      customer: @customer,
      name: "Report Site"
    )

    @other_customer = Customer.create!(
      organization: @other_organization,
      customer_type: "individual",
      first_name: "Other",
      last_name: "Customer",
      email: "other-customer-reports@example.com"
    )

    @other_site = Site.create!(
      organization: @other_organization,
      customer: @other_customer,
      name: "Other Report Site"
    )

    @job = Job.create!(
      organization: @organization,
      customer: @customer,
      site: @site,
      title: "Garden Maintenance",
      job_type: "maintenance",
      status: "completed",
      priority: "normal",
      scheduled_date: Date.current
    )

    @other_job = Job.create!(
      organization: @other_organization,
      customer: @other_customer,
      site: @other_site,
      title: "Other Organization Job",
      job_type: "maintenance",
      status: "completed",
      priority: "normal",
      scheduled_date: Date.current
    )

    @report = JobReport.create!(
      organization: @organization,
      job: @job,
      summary: "Garden maintenance completed",
      work_performed: "Lawn mowing and hedge trimming",
      observations: "Garden in good condition",
      recommendations: "Continue regular maintenance",
      generated_at: Time.zone.parse("2026-08-22 17:00:00")
    )

    @other_report = JobReport.create!(
      organization: @other_organization,
      job: @other_job,
      summary: "Other organization report",
      work_performed: "Other work",
      generated_at: Time.zone.parse("2026-08-22 17:00:00")
    )

    @manager_token = JwtService.encode(@manager)
    @owner_token = JwtService.encode(@owner)
    @member_token = JwtService.encode(@member)
    @other_manager_token = JwtService.encode(@other_manager)
  end

  test "index requires authentication" do
    get "/api/v1/job_reports"

    assert_response :unauthorized
  end

  test "index returns reports from the current organization" do
    get "/api/v1/job_reports",
        headers: {
          "Authorization" => "Bearer #{@manager_token}"
        }

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal 1, body.length
    assert_equal @report.id, body.first["id"]
  end

  test "show returns a report from the same organization" do
    get "/api/v1/job_reports/#{@report.id}",
        headers: {
          "Authorization" => "Bearer #{@manager_token}"
        }

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal @report.id, body["id"]
    assert_equal @job.id, body["job_id"]
  end

  test "show cannot access a report from another organization" do
    get "/api/v1/job_reports/#{@other_report.id}",
        headers: {
          "Authorization" => "Bearer #{@manager_token}"
        }

    assert_response :not_found
  end

  test "manager can create a report" do
    assert_difference("JobReport.count", 1) do
      post "/api/v1/job_reports",
           params: {
             job_report: {
               job_id: @job.id,
               summary: "New job report",
               work_performed: "Complete garden maintenance",
               observations: "Everything completed correctly",
               recommendations: "Schedule next visit",
               generated_at: Time.zone.parse("2026-08-22 18:00:00")
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
    assert_equal "New job report", body["summary"]
  end

  test "member cannot create a report" do
    assert_no_difference("JobReport.count") do
      post "/api/v1/job_reports",
           params: {
             job_report: {
               job_id: @job.id,
               summary: "Unauthorized report"
             }
           },
           headers: {
             "Authorization" => "Bearer #{@member_token}"
           }
    end

    assert_response :forbidden
  end

  test "manager can update a report" do
    patch "/api/v1/job_reports/#{@report.id}",
          params: {
            job_report: {
              summary: "Updated report",
              recommendations: "Updated recommendations"
            }
          },
          headers: {
            "Authorization" => "Bearer #{@manager_token}"
          }

    assert_response :success

    report = @report.reload

    assert_equal "Updated report", report.summary
    assert_equal "Updated recommendations", report.recommendations
  end

  test "member cannot update a report" do
    patch "/api/v1/job_reports/#{@report.id}",
          params: {
            job_report: {
              summary: "Unauthorized update"
            }
          },
          headers: {
            "Authorization" => "Bearer #{@member_token}"
          }

    assert_response :forbidden

    assert_equal "Garden maintenance completed", @report.reload.summary
  end

  test "owner can destroy a report" do
    assert_difference("JobReport.count", -1) do
      delete "/api/v1/job_reports/#{@report.id}",
             headers: {
               "Authorization" => "Bearer #{@owner_token}"
             }
    end

    assert_response :no_content
  end

  test "manager cannot destroy a report" do
    assert_no_difference("JobReport.count") do
      delete "/api/v1/job_reports/#{@report.id}",
             headers: {
               "Authorization" => "Bearer #{@manager_token}"
             }
    end

    assert_response :forbidden
  end

  test "member cannot destroy a report" do
    assert_no_difference("JobReport.count") do
      delete "/api/v1/job_reports/#{@report.id}",
             headers: {
               "Authorization" => "Bearer #{@member_token}"
             }
    end

    assert_response :forbidden
  end

  test "cannot create a report with a job from another organization" do
    assert_no_difference("JobReport.count") do
      post "/api/v1/job_reports",
           params: {
             job_report: {
               job_id: @other_job.id,
               summary: "Cross organization report"
             }
           },
           headers: {
             "Authorization" => "Bearer #{@manager_token}"
           }
    end

    assert_response :forbidden
  end

  test "cannot access a report with mismatched organization and job" do
    invalid_report = JobReport.create!(
      organization: @organization,
      job: @other_job,
      summary: "Invalid cross organization report"
    )

    get "/api/v1/job_reports/#{invalid_report.id}",
        headers: {
          "Authorization" => "Bearer #{@manager_token}"
        }

    assert_response :not_found
  end

  private

  def create_user(organization:, email:, role:)
    User.create!(
      organization: organization,
      email: email,
      password: "Password123!",
      password_confirmation: "Password123!",
      first_name: "Test",
      last_name: "User",
      role: role
    )
  end
end