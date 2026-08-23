require "test_helper"

class JobTest < ActiveSupport::TestCase
  setup do
    @organization = Organization.create!(name: "GreenPilot Job Test", slug: "greenpilot-job-test")

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
  end

  test "belongs to required organization customer and site" do
    assert_equal :belongs_to, Job.reflect_on_association(:organization).macro
    assert_equal :belongs_to, Job.reflect_on_association(:customer).macro
    assert_equal :belongs_to, Job.reflect_on_association(:site).macro
  end

  test "has optional quote team and vehicle" do
    assert Job.reflect_on_association(:quote).options[:optional]
    assert Job.reflect_on_association(:team).options[:optional]
    assert Job.reflect_on_association(:vehicle).options[:optional]
  end

  test "has assignments users time entries and reports" do
    assert_equal :has_many, Job.reflect_on_association(:job_assignments).macro
    assert_equal :has_many, Job.reflect_on_association(:users).macro
    assert_equal :has_many, Job.reflect_on_association(:job_time_entries).macro
    assert_equal :has_many, Job.reflect_on_association(:job_reports).macro
  end

  test "requires title and job type" do
    job = Job.new(
      organization: @organization,
      customer: @customer,
      site: @site
    )

    refute job.valid?
    assert job.errors[:title].any?
    assert job.errors[:job_type].any?
  end

  test "durations cannot be negative" do
    job = Job.new(
      organization: @organization,
      customer: @customer,
      site: @site,
      title: "Garden Maintenance",
      job_type: "maintenance",
      estimated_duration_minutes: -1
    )

    refute job.valid?
    assert job.errors[:estimated_duration_minutes].any?
  end

  test "planned scope returns planned jobs" do
    job = Job.create!(
      organization: @organization,
      customer: @customer,
      site: @site,
      title: "Garden Maintenance",
      job_type: "maintenance",
      status: "planned"
    )

    assert_includes Job.planned, job
  end

  test "by_date scope filters scheduled date" do
    date = Date.current

    job = Job.create!(
      organization: @organization,
      customer: @customer,
      site: @site,
      title: "Garden Maintenance",
      job_type: "maintenance",
      scheduled_date: date
    )

    assert_includes Job.by_date(date), job
    assert_not_includes Job.by_date(date + 1.day), job
  end
end
