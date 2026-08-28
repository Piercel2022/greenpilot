
require "test_helper"

class JobAssignmentPolicyTest < ActiveSupport::TestCase
  setup do
    @owner = users(:owner_a)
    @admin = users(:admin_a)
    @manager = users(:manager_a)
    @accountant = users(:accountant_a)
    @field_worker = users(:field_worker_a)
    @member = users(:member_a)

    @assignment = job_assignments(:assignment_a)
    @other_assignment = job_assignments(:assignment_b)

    @job = jobs(:job_a)
    @other_job = jobs(:job_b)

    @other_user = users(:field_worker_b)
  end

  # ============================================================
  # INDEX
  # ============================================================

  test "authenticated user can list job assignments" do
    assert JobAssignmentPolicy.new(@member, JobAssignment).index?
  end

  # ============================================================
  # SHOW
  # ============================================================

  test "user can view assignment from same organization" do
    assert JobAssignmentPolicy.new(@member, @assignment).show?
  end

  test "user cannot view assignment from another organization" do
    assert_not JobAssignmentPolicy.new(@member, @other_assignment).show?
  end

  test "user cannot view assignment with foreign job" do
    @assignment.job = @other_job

    assert_not JobAssignmentPolicy.new(@member, @assignment).show?
  end

  test "user cannot view assignment with foreign user" do
    @assignment.user = @other_user

    assert_not JobAssignmentPolicy.new(@member, @assignment).show?
  end

  # ============================================================
  # CREATE
  # ============================================================

  test "owner can create assignment" do
    assignment = JobAssignment.new(
      organization: @owner.organization,
      job: @job,
      user: @field_worker,
      assignment_type: "primary",
      role: "worker",
      active: true
    )

    assert JobAssignmentPolicy.new(@owner, assignment).create?
  end

  test "admin can create assignment" do
    assignment = JobAssignment.new(
      organization: @admin.organization,
      job: @job,
      user: @field_worker,
      assignment_type: "primary",
      role: "worker",
      active: true
    )

    assert JobAssignmentPolicy.new(@admin, assignment).create?
  end

  test "manager can create assignment" do
    assignment = JobAssignment.new(
      organization: @manager.organization,
      job: @job,
      user: @field_worker,
      assignment_type: "primary",
      role: "worker",
      active: true
    )

    assert JobAssignmentPolicy.new(@manager, assignment).create?
  end

  test "accountant cannot create assignment" do
    assignment = JobAssignment.new(
      organization: @accountant.organization,
      job: @job,
      user: @field_worker,
      assignment_type: "primary",
      role: "worker",
      active: true
    )

    assert_not JobAssignmentPolicy.new(@accountant, assignment).create?
  end

  test "field worker cannot create assignment" do
    assignment = JobAssignment.new(
      organization: @field_worker.organization,
      job: @job,
      user: @field_worker,
      assignment_type: "primary",
      role: "worker",
      active: true
    )

    assert_not JobAssignmentPolicy.new(@field_worker, assignment).create?
  end

  test "member cannot create assignment" do
    assignment = JobAssignment.new(
      organization: @member.organization,
      job: @job,
      user: @field_worker,
      assignment_type: "primary",
      role: "worker",
      active: true
    )

    assert_not JobAssignmentPolicy.new(@member, assignment).create?
  end

  test "manager cannot create assignment for foreign job" do
    assignment = JobAssignment.new(
      organization: @manager.organization,
      job: @other_job,
      user: @field_worker,
      assignment_type: "primary",
      role: "worker",
      active: true
    )

    assert_not JobAssignmentPolicy.new(@manager, assignment).create?
  end

  test "manager cannot create assignment for foreign user" do
    assignment = JobAssignment.new(
      organization: @manager.organization,
      job: @job,
      user: @other_user,
      assignment_type: "primary",
      role: "worker",
      active: true
    )

    assert_not JobAssignmentPolicy.new(@manager, assignment).create?
  end

  test "manager cannot create assignment from foreign organization" do
    assignment = JobAssignment.new(
      organization: @other_assignment.organization,
      job: @other_job,
      user: @other_user,
      assignment_type: "primary",
      role: "worker",
      active: true
    )

    assert_not JobAssignmentPolicy.new(@manager, assignment).create?
  end

  # ============================================================
  # UPDATE
  # ============================================================

  test "owner can update assignment" do
    assert JobAssignmentPolicy.new(@owner, @assignment).update?
  end

  test "admin can update assignment" do
    assert JobAssignmentPolicy.new(@admin, @assignment).update?
  end

  test "manager can update assignment" do
    assert JobAssignmentPolicy.new(@manager, @assignment).update?
  end

  test "accountant cannot update assignment" do
    assert_not JobAssignmentPolicy.new(@accountant, @assignment).update?
  end

  test "field worker cannot update assignment" do
    assert_not JobAssignmentPolicy.new(@field_worker, @assignment).update?
  end

  test "member cannot update assignment" do
    assert_not JobAssignmentPolicy.new(@member, @assignment).update?
  end

  test "manager cannot update assignment from another organization" do
    assert_not JobAssignmentPolicy.new(@manager, @other_assignment).update?
  end

  test "manager cannot update assignment with foreign job" do
    @assignment.job = @other_job

    assert_not JobAssignmentPolicy.new(@manager, @assignment).update?
  end

  test "manager cannot update assignment with foreign user" do
    @assignment.user = @other_user

    assert_not JobAssignmentPolicy.new(@manager, @assignment).update?
  end

  # ============================================================
  # DESTROY
  # ============================================================

  test "owner can destroy assignment" do
    assert JobAssignmentPolicy.new(@owner, @assignment).destroy?
  end

  test "admin can destroy assignment" do
    assert JobAssignmentPolicy.new(@admin, @assignment).destroy?
  end

  test "manager can destroy assignment" do
    assert JobAssignmentPolicy.new(@manager, @assignment).destroy?
  end

  test "accountant cannot destroy assignment" do
    assert_not JobAssignmentPolicy.new(@accountant, @assignment).destroy?
  end

  test "field worker cannot destroy assignment" do
    assert_not JobAssignmentPolicy.new(@field_worker, @assignment).destroy?
  end

  test "member cannot destroy assignment" do
    assert_not JobAssignmentPolicy.new(@member, @assignment).destroy?
  end

  test "manager cannot destroy assignment from another organization" do
    assert_not JobAssignmentPolicy.new(@manager, @other_assignment).destroy?
  end

  test "manager cannot destroy assignment with foreign job" do
    @assignment.job = @other_job

    assert_not JobAssignmentPolicy.new(@manager, @assignment).destroy?
  end

  test "manager cannot destroy assignment with foreign user" do
    @assignment.user = @other_user

    assert_not JobAssignmentPolicy.new(@manager, @assignment).destroy?
  end

  # ============================================================
  # SCOPE
  # ============================================================

  test "scope returns only assignments from user's organization" do
    result = JobAssignmentPolicy::Scope
      .new(@member, JobAssignment.all)
      .resolve

    assert_equal [@assignment.id], result.pluck(:id)
  end

  test "scope excludes assignments with foreign job organization" do
    foreign_job_assignment = JobAssignment.create!(
      organization: @assignment.organization,
      job: @other_job,
      user: @field_worker,
      assignment_type: "secondary",
      role: "worker",
      active: true
    )

    result = JobAssignmentPolicy::Scope
      .new(@manager, JobAssignment.all)
      .resolve

    assert_not_includes result.pluck(:id), foreign_job_assignment.id
  end

  test "scope excludes assignments with foreign user organization" do
    foreign_user_assignment = JobAssignment.create!(
      organization: @assignment.organization,
      job: @job,
      user: @other_user,
      assignment_type: "secondary",
      role: "worker",
      active: true
    )

    result = JobAssignmentPolicy::Scope
      .new(@manager, JobAssignment.all)
      .resolve

    assert_not_includes result.pluck(:id), foreign_user_assignment.id
  end

  test "scope includes only assignments whose organization job and user all match" do
    result = JobAssignmentPolicy::Scope
      .new(@manager, JobAssignment.all)
      .resolve

    assert result.all? do |assignment|
      assignment.organization_id == @manager.organization_id &&
        assignment.job.organization_id == @manager.organization_id &&
        assignment.user.organization_id == @manager.organization_id
    end
  end
end