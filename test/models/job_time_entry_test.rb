require "test_helper"

class JobTimeEntryTest < ActiveSupport::TestCase
  setup do
    @organization = Organization.create!(name: "GreenPilot Time Test", slug: "greenpilot-time-test")

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

    @user = User.create!(
  organization: @organization,
  email: "worker@example.com",
  first_name: "Field",
  last_name: "Worker",
  password: "password123",
  password_confirmation: "password123"
)

    @job = Job.create!(
      organization: @organization,
      customer: @customer,
      site: @site,
      title: "Garden Maintenance",
      job_type: "maintenance"
    )
  end

  test "belongs to organization job and user" do
    assert_equal :belongs_to, JobTimeEntry.reflect_on_association(:organization).macro
    assert_equal :belongs_to, JobTimeEntry.reflect_on_association(:job).macro
    assert_equal :belongs_to, JobTimeEntry.reflect_on_association(:user).macro
  end

  test "requires started at" do
  entry = JobTimeEntry.new(
    organization: @organization,
    job: @job,
    user: @user
  )

  refute entry.valid?
  assert entry.errors[:started_at].any?
 end

 test "uses work as default entry type" do
  entry = JobTimeEntry.new(
    organization: @organization,
    job: @job,
    user: @user
  )

  assert_equal "work", entry.entry_type
 end

  test "duration cannot be negative" do
    entry = JobTimeEntry.new(
      organization: @organization,
      job: @job,
      user: @user,
      started_at: Time.current,
      duration_minutes: -1
    )

    refute entry.valid?
    assert entry.errors[:duration_minutes].any?
  end
end
