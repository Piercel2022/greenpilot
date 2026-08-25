require "test_helper"

class JobPolicyTest < ActiveSupport::TestCase
  # ============================================================
  # INDEX
  # ============================================================

  test "authenticated user can list jobs" do
    user = users(:member_a)

    assert JobPolicy.new(user, Job).index?
  end

  # ============================================================
  # SHOW
  # ============================================================

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

  test "user cannot view job with foreign customer" do
    user = users(:member_a)
    job = jobs(:job_a)

    job.customer = customers(:customer_b)

    assert_not JobPolicy.new(user, job).show?
  end

  test "user cannot view job with foreign site" do
    user = users(:member_a)
    job = jobs(:job_a)

    job.site = sites(:site_b)

    assert_not JobPolicy.new(user, job).show?
  end

  test "user cannot view job with foreign quote" do
    user = users(:member_a)
    job = jobs(:job_a)

    job.quote = quotes(:quote_b)

    assert_not JobPolicy.new(user, job).show?
  end

  test "user cannot view job with foreign team" do
    user = users(:member_a)
    job = jobs(:job_a)

    job.team = teams(:team_b)

    assert_not JobPolicy.new(user, job).show?
  end

  test "user cannot view job with foreign vehicle" do
    user = users(:member_a)
    job = jobs(:job_a)

    job.vehicle = vehicles(:vehicle_b)

    assert_not JobPolicy.new(user, job).show?
  end

  # ============================================================
  # CREATE
  # ============================================================

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

  test "manager cannot create job with foreign quote" do
    user = users(:manager_a)

    job = Job.new(
      organization: user.organization,
      customer: customers(:customer_a),
      site: sites(:site_a),
      quote: quotes(:quote_b),
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

  # ============================================================
  # UPDATE
  # ============================================================

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

  test "accountant cannot update job" do
    user = users(:accountant_a)
    job = jobs(:job_a)

    assert_not JobPolicy.new(user, job).update?
  end

  test "manager can update job" do
    user = users(:manager_a)
    job = jobs(:job_a)

    assert JobPolicy.new(user, job).update?
  end

  test "admin can update job" do
    user = users(:admin_a)
    job = jobs(:job_a)

    assert JobPolicy.new(user, job).update?
  end

  test "owner can update job" do
    user = users(:owner_a)
    job = jobs(:job_a)

    assert JobPolicy.new(user, job).update?
  end

  test "manager cannot update job from another organization" do
    user = users(:manager_a)
    job = jobs(:job_b)

    assert_not JobPolicy.new(user, job).update?
  end

  test "manager cannot update job with foreign customer" do
    user = users(:manager_a)
    job = jobs(:job_a)

    job.customer = customers(:customer_b)

    assert_not JobPolicy.new(user, job).update?
  end

  test "manager cannot update job with foreign site" do
    user = users(:manager_a)
    job = jobs(:job_a)

    job.site = sites(:site_b)

    assert_not JobPolicy.new(user, job).update?
  end

  test "manager cannot update job with foreign quote" do
    user = users(:manager_a)
    job = jobs(:job_a)

    job.quote = quotes(:quote_b)

    assert_not JobPolicy.new(user, job).update?
  end

  test "manager cannot update job with foreign team" do
    user = users(:manager_a)
    job = jobs(:job_a)

    job.team = teams(:team_b)

    assert_not JobPolicy.new(user, job).update?
  end

  test "manager cannot update job with foreign vehicle" do
    user = users(:manager_a)
    job = jobs(:job_a)

    job.vehicle = vehicles(:vehicle_b)

    assert_not JobPolicy.new(user, job).update?
  end

  # ============================================================
  # DESTROY
  # ============================================================

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

  test "member cannot destroy job" do
    user = users(:member_a)
    job = jobs(:job_a)

    assert_not JobPolicy.new(user, job).destroy?
  end

  test "accountant cannot destroy job" do
    user = users(:accountant_a)
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

  test "owner cannot destroy job with foreign customer" do
    user = users(:owner_a)
    job = jobs(:job_a)

    job.customer = customers(:customer_b)

    assert_not JobPolicy.new(user, job).destroy?
  end

  test "owner cannot destroy job with foreign site" do
    user = users(:owner_a)
    job = jobs(:job_a)

    job.site = sites(:site_b)

    assert_not JobPolicy.new(user, job).destroy?
  end

  test "owner cannot destroy job with foreign quote" do
    user = users(:owner_a)
    job = jobs(:job_a)

    job.quote = quotes(:quote_b)

    assert_not JobPolicy.new(user, job).destroy?
  end

  test "owner cannot destroy job with foreign team" do
    user = users(:owner_a)
    job = jobs(:job_a)

    job.team = teams(:team_b)

    assert_not JobPolicy.new(user, job).destroy?
  end

  test "owner cannot destroy job with foreign vehicle" do
    user = users(:owner_a)
    job = jobs(:job_a)

    job.vehicle = vehicles(:vehicle_b)

    assert_not JobPolicy.new(user, job).destroy?
  end

  # ============================================================
  # SCOPE
  # ============================================================

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

  test "scope excludes jobs with foreign quote" do
    user = users(:member_a)

    job = jobs(:job_a)
    job.update_column(:quote_id, quotes(:quote_b).id)

    result = JobPolicy::Scope
      .new(user, Job.all)
      .resolve

    assert_not_includes result, job
  end

  test "scope excludes jobs with foreign team" do
    user = users(:member_a)

    job = jobs(:job_a)
    job.update_column(:team_id, teams(:team_b).id)

    result = JobPolicy::Scope
      .new(user, Job.all)
      .resolve

    assert_not_includes result, job
  end

  test "scope excludes jobs with foreign vehicle" do
    user = users(:member_a)

    job = jobs(:job_a)
    job.update_column(:vehicle_id, vehicles(:vehicle_b).id)

    result = JobPolicy::Scope
      .new(user, Job.all)
      .resolve

    assert_not_includes result, job
  end
end