require "test_helper"

class JobAssignmentTest < ActiveSupport::TestCase
  setup do
    @organization = Organization.create!(name: "GreenPilot Assignment Test", slug: "greenpilot-assignment-test")

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
    assert_equal :belongs_to, JobAssignment.reflect_on_association(:organization).macro
    assert_equal :belongs_to, JobAssignment.reflect_on_association(:job).macro
    assert_equal :belongs_to, JobAssignment.reflect_on_association(:user).macro
  end

  test "uses default assignment type and role" do
  assignment = JobAssignment.new(
    organization: @organization,
    job: @job,
    user: @user
  )

  assert_equal "primary", assignment.assignment_type
  assert_equal "worker", assignment.role
  assert assignment.valid?
end

  test "user can only be assigned once to a job" do
    JobAssignment.create!(
      organization: @organization,
      job: @job,
      user: @user,
      assignment_type: "primary",
      role: "worker"
    )

    duplicate = JobAssignment.new(
      organization: @organization,
      job: @job,
      user: @user,
      assignment_type: "secondary",
      role: "worker"
    )

    refute duplicate.valid?
    assert duplicate.errors[:user_id].any?
  end

  test "active and inactive scopes work" do
    assignment = JobAssignment.create!(
      organization: @organization,
      job: @job,
      user: @user,
      assignment_type: "primary",
      role: "worker",
      active: true
    )

    assert_includes JobAssignment.active, assignment
    assert_not_includes JobAssignment.inactive, assignment
  end
end
