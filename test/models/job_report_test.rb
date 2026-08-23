require "test_helper"

class JobReportTest < ActiveSupport::TestCase
  setup do
    @organization = Organization.create!(name: "GreenPilot Report Test", slug: "greenpilot-report-test")

    @customer = Customer.create!(
      organization: @organization,
      first_name: "John",
      last_name: "Customer"
    )

    @site = Site.create!(
      organization: @organization,
      customer: @customer,
      name: "Customer Site"
    )

    @job = Job.create!(
      organization: @organization,
      customer: @customer,
      site: @site,
      title: "Garden Maintenance",
      job_type: "maintenance"
    )
  end

  test "belongs to organization and job" do
    assert_equal :belongs_to, JobReport.reflect_on_association(:organization).macro
    assert_equal :belongs_to, JobReport.reflect_on_association(:job).macro
  end

  test "generated scope returns generated reports" do
    report = JobReport.create!(
      organization: @organization,
      job: @job,
      generated_at: Time.current
    )

    assert_includes JobReport.generated, report
    assert_not_includes JobReport.not_generated, report
  end

  test "sent scope returns sent reports" do
    report = JobReport.create!(
      organization: @organization,
      job: @job,
      sent_to_customer_at: Time.current
    )

    assert_includes JobReport.sent, report
    assert_not_includes JobReport.not_sent, report
  end

  test "signed scope returns signed reports" do
    report = JobReport.create!(
      organization: @organization,
      job: @job,
      customer_signed_at: Time.current
    )

    assert_includes JobReport.signed, report
    assert_not_includes JobReport.unsigned, report
  end
end
