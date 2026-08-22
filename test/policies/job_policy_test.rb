require "test_helper"

class JobPolicyTest < ActiveSupport::TestCase
  test "authenticated user can list jobs" do
    user = users(:member_a)

    assert JobPolicy.new(user, Job).index?
  end

  test "user can view job from same organization" do
    user = users(:member_a)
    job = jobs(:job_a)

    assert JobPolicy.new(user, job).show?
  end

  test "user cannot view job from another organization" do
    user = users(:member_a)
    job = jobs(:job_b)

    assert_not JobPolicy.new(user, job).show?
  end

  test "manager can create job" do
    user = users(:manager_a)

    job = Job.new(
      organization: user.organization,
      customer: customers(:customer_a),
      site: sites(:site_a),
      title: "Nouvelle intervention",
      job_type: "maintenance"
    )

    assert JobPolicy.new(user, job).create?
  end

  test "member cannot create job" do
    user = users(:member_a)

    job = Job.new(
      organization: user.organization,
      customer: customers(:customer_a),
      site: sites(:site_a),
      title: "Nouvelle intervention",
      job_type: "maintenance"
    )

    assert_not JobPolicy.new(user, job).create?
  end

  test "accountant cannot create job" do
    user = users(:accountant_a)

    job = Job.new(
      organization: user.organization,
      customer: customers(:customer_a),
      site: sites(:site_a),
      title: "Nouvelle intervention",
      job_type: "maintenance"
    )

    assert_not JobPolicy.new(user, job).create?
  end

  test "assigned field worker can update job" do
    user = users(:field_worker_a)
    job = jobs(:job_a)

    assert JobPolicy.new(user, job).update?
  end

  test "unassigned field worker cannot update job" do
    user = users(:field_worker_a)
    job = jobs(:job_b)

    assert_not JobPolicy.new(user, job).update?
  end

  test "member cannot update job" do
    user = users(:member_a)
    job = jobs(:job_a)

    assert_not JobPolicy.new(user, job).update?
  end

  test "manager can update job" do
    user = users(:manager_a)
    job = jobs(:job_a)

    assert JobPolicy.new(user, job).update?
  end

  test "manager cannot update job from another organization" do
    user = users(:manager_a)
    job = jobs(:job_b)

    assert_not JobPolicy.new(user, job).update?
  end

  test "owner can destroy job" do
    user = users(:owner_a)
    job = jobs(:job_a)

    assert JobPolicy.new(user, job).destroy?
  end

  test "admin can destroy job" do
    user = users(:admin_a)
    job = jobs(:job_a)

    assert JobPolicy.new(user, job).destroy?
  end

  test "manager cannot destroy job" do
    user = users(:manager_a)
    job = jobs(:job_a)

    assert_not JobPolicy.new(user, job).destroy?
  end

  test "field worker cannot destroy job" do
    user = users(:field_worker_a)
    job = jobs(:job_a)

    assert_not JobPolicy.new(user, job).destroy?
  end

  test "owner cannot destroy job from another organization" do
    user = users(:owner_a)
    job = jobs(:job_b)

    assert_not JobPolicy.new(user, job).destroy?
  end

  test "manager cannot create job for foreign customer" do
    user = users(:manager_a)

    job = Job.new(
      organization: user.organization,
      customer: customers(:customer_b),
      site: sites(:site_a),
      title: "Cross organization",
      job_type: "maintenance"
    )

    assert_not JobPolicy.new(user, job).create?
  end

  test "manager cannot create job for foreign site" do
    user = users(:manager_a)

    job = Job.new(
      organization: user.organization,
      customer: customers(:customer_a),
      site: sites(:site_b),
      title: "Cross organization",
      job_type: "maintenance"
    )

    assert_not JobPolicy.new(user, job).create?
  end

  test "manager cannot create job with foreign team" do
    user = users(:manager_a)

    job = Job.new(
      organization: user.organization,
      customer: customers(:customer_a),
      site: sites(:site_a),
      team: teams(:team_b),
      title: "Cross organization",
      job_type: "maintenance"
    )

    assert_not JobPolicy.new(user, job).create?
  end

  test "manager cannot create job with foreign vehicle" do
    user = users(:manager_a)

    job = Job.new(
      organization: user.organization,
      customer: customers(:customer_a),
      site: sites(:site_a),
      vehicle: vehicles(:vehicle_b),
      title: "Cross organization",
      job_type: "maintenance"
    )

    assert_not JobPolicy.new(user, job).create?
  end

  test "scope returns only jobs from user's organization" do
    user = users(:member_a)

    result = JobPolicy::Scope
      .new(user, Job.all)
      .resolve

    assert result.all? do |job|
      job.organization_id == user.organization_id &&
        job.customer.organization_id == user.organization_id &&
        job.site.organization_id == user.organization_id
    end
  end
end