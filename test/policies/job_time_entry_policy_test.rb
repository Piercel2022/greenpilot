
require "test_helper"

class JobTimeEntryPolicyTest < ActiveSupport::TestCase
  setup do
    @organization = Organization.create!(
      name: "Policy Time Entries Test",
      slug: "policy-time-entries-test"
    )

    @other_organization = Organization.create!(
      name: "Other Policy Organization",
      slug: "other-policy-time-entries-test"
    )

    @manager = create_user(
      organization: @organization,
      email: "manager-policy-time@example.com",
      role: "manager"
    )

    @owner = create_user(
      organization: @organization,
      email: "owner-policy-time@example.com",
      role: "owner"
    )

    @admin = create_user(
      organization: @organization,
      email: "admin-policy-time@example.com",
      role: "admin"
    )

    @field_worker = create_user(
      organization: @organization,
      email: "worker-policy-time@example.com",
      role: "field_worker"
    )

    @unassigned_worker = create_user(
      organization: @organization,
      email: "unassigned-policy-time@example.com",
      role: "field_worker"
    )

    @member = create_user(
      organization: @organization,
      email: "member-policy-time@example.com",
      role: "member"
    )

    @accountant = create_user(
      organization: @organization,
      email: "accountant-policy-time@example.com",
      role: "accountant"
    )

    @other_worker = create_user(
      organization: @other_organization,
      email: "other-worker-policy-time@example.com",
      role: "field_worker"
    )

    @customer = Customer.create!(
      organization: @organization,
      customer_type: "individual",
      first_name: "Policy",
      last_name: "Customer",
      email: "policy-customer@example.com"
    )

    @other_customer = Customer.create!(
      organization: @other_organization,
      customer_type: "individual",
      first_name: "Other",
      last_name: "Customer",
      email: "other-policy-customer@example.com"
    )

    @site = Site.create!(
      organization: @organization,
      customer: @customer,
      name: "Policy Time Site"
    )

    @other_site = Site.create!(
      organization: @other_organization,
      customer: @other_customer,
      name: "Other Policy Time Site"
    )

    @job = Job.create!(
      organization: @organization,
      customer: @customer,
      site: @site,
      title: "Policy Garden Job",
      job_type: "maintenance",
      status: "in_progress",
      priority: "normal",
      scheduled_date: Date.current
    )

    @other_job = Job.create!(
      organization: @other_organization,
      customer: @other_customer,
      site: @other_site,
      title: "Other Policy Job",
      job_type: "maintenance",
      status: "in_progress",
      priority: "normal",
      scheduled_date: Date.current
    )

    JobAssignment.create!(
      organization: @organization,
      job: @job,
      user: @field_worker,
      assignment_type: "primary",
      role: "worker",
      active: true
    )

    JobAssignment.create!(
      organization: @other_organization,
      job: @other_job,
      user: @other_worker,
      assignment_type: "primary",
      role: "worker",
      active: true
    )

    @time_entry = JobTimeEntry.create!(
      organization: @organization,
      job: @job,
      user: @field_worker,
      entry_type: "work",
      started_at: Time.zone.parse("2026-08-24 08:00:00"),
      ended_at: Time.zone.parse("2026-08-24 10:00:00"),
      duration_minutes: 120,
      notes: "Morning work"
    )

    @manager_entry = JobTimeEntry.create!(
      organization: @organization,
      job: @job,
      user: @manager,
      entry_type: "work",
      started_at: Time.zone.parse("2026-08-24 11:00:00"),
      ended_at: Time.zone.parse("2026-08-24 12:00:00"),
      duration_minutes: 60
    )

    @other_time_entry = JobTimeEntry.create!(
      organization: @other_organization,
      job: @other_job,
      user: @other_worker,
      entry_type: "work",
      started_at: Time.zone.parse("2026-08-24 08:00:00"),
      ended_at: Time.zone.parse("2026-08-24 10:00:00"),
      duration_minutes: 120
    )
  end

  # ============================================================
  # INDEX
  # ============================================================

  test "authenticated user can list time entries" do
    assert JobTimeEntryPolicy.new(@member, JobTimeEntry).index?
  end

  # ============================================================
  # SHOW
  # ============================================================

  test "manager can view time entry from same organization" do
    assert JobTimeEntryPolicy.new(@manager, @time_entry).show?
  end

  test "assigned field worker can view their own time entry" do
    assert JobTimeEntryPolicy.new(@field_worker, @time_entry).show?
  end

  test "field worker cannot view another user's time entry" do
    assert_not JobTimeEntryPolicy.new(@field_worker, @manager_entry).show?
  end

  test "member cannot view time entry" do
    assert_not JobTimeEntryPolicy.new(@member, @time_entry).show?
  end

  test "accountant cannot view time entry" do
    assert_not JobTimeEntryPolicy.new(@accountant, @time_entry).show?
  end

  test "user cannot view time entry from another organization" do
    assert_not JobTimeEntryPolicy.new(@manager, @other_time_entry).show?
  end

  test "manager cannot view time entry with foreign job" do
    @time_entry.job = @other_job

    assert_not JobTimeEntryPolicy.new(@manager, @time_entry).show?
  end

  test "manager cannot view time entry with foreign user" do
    @time_entry.user = @other_worker

    assert_not JobTimeEntryPolicy.new(@manager, @time_entry).show?
  end

  # ============================================================
  # CREATE
  # ============================================================

  test "manager can create time entry" do
    entry = JobTimeEntry.new(
      organization: @organization,
      job: @job,
      user: @field_worker,
      entry_type: "work"
    )

    assert JobTimeEntryPolicy.new(@manager, entry).create?
  end

  test "owner can create time entry" do
    entry = JobTimeEntry.new(
      organization: @organization,
      job: @job,
      user: @field_worker,
      entry_type: "work"
    )

    assert JobTimeEntryPolicy.new(@owner, entry).create?
  end

  test "admin can create time entry" do
    entry = JobTimeEntry.new(
      organization: @organization,
      job: @job,
      user: @field_worker,
      entry_type: "work"
    )

    assert JobTimeEntryPolicy.new(@admin, entry).create?
  end

  test "assigned field worker can create time entry" do
    entry = JobTimeEntry.new(
      organization: @organization,
      job: @job,
      user: @field_worker,
      entry_type: "work"
    )

    assert JobTimeEntryPolicy.new(@field_worker, entry).create?
  end

  test "unassigned field worker cannot create time entry" do
    entry = JobTimeEntry.new(
      organization: @organization,
      job: @job,
      user: @unassigned_worker,
      entry_type: "work"
    )

    assert_not JobTimeEntryPolicy.new(@unassigned_worker, entry).create?
  end

  test "member cannot create time entry" do
    entry = JobTimeEntry.new(
      organization: @organization,
      job: @job,
      user: @field_worker,
      entry_type: "work"
    )

    assert_not JobTimeEntryPolicy.new(@member, entry).create?
  end

  test "accountant cannot create time entry" do
    entry = JobTimeEntry.new(
      organization: @organization,
      job: @job,
      user: @field_worker,
      entry_type: "work"
    )

    assert_not JobTimeEntryPolicy.new(@accountant, entry).create?
  end

  test "manager cannot create time entry for foreign organization" do
    entry = JobTimeEntry.new(
      organization: @organization,
      job: @other_job,
      user: @field_worker,
      entry_type: "work"
    )

    assert_not JobTimeEntryPolicy.new(@manager, entry).create?
  end

  test "manager cannot create time entry for foreign user" do
    entry = JobTimeEntry.new(
      organization: @organization,
      job: @job,
      user: @other_worker,
      entry_type: "work"
    )

    assert_not JobTimeEntryPolicy.new(@manager, entry).create?
  end

  # ============================================================
  # UPDATE
  # ============================================================

  test "manager can update time entry" do
    assert JobTimeEntryPolicy.new(@manager, @time_entry).update?
  end

  test "owner can update time entry" do
    assert JobTimeEntryPolicy.new(@owner, @time_entry).update?
  end

  test "admin can update time entry" do
    assert JobTimeEntryPolicy.new(@admin, @time_entry).update?
  end

  test "assigned field worker can update their own time entry" do
    assert JobTimeEntryPolicy.new(@field_worker, @time_entry).update?
  end

  test "field worker cannot update another user's time entry" do
    assert_not JobTimeEntryPolicy.new(@field_worker, @manager_entry).update?
  end

  test "unassigned field worker cannot update time entry" do
    assert_not JobTimeEntryPolicy.new(@unassigned_worker, @time_entry).update?
  end

  test "member cannot update time entry" do
    assert_not JobTimeEntryPolicy.new(@member, @time_entry).update?
  end

  test "accountant cannot update time entry" do
    assert_not JobTimeEntryPolicy.new(@accountant, @time_entry).update?
  end

  test "manager cannot update time entry from another organization" do
    assert_not JobTimeEntryPolicy.new(@manager, @other_time_entry).update?
  end

  test "manager cannot update time entry with foreign job" do
    @time_entry.job = @other_job

    assert_not JobTimeEntryPolicy.new(@manager, @time_entry).update?
  end

  test "manager cannot update time entry with foreign user" do
    @time_entry.user = @other_worker

    assert_not JobTimeEntryPolicy.new(@manager, @time_entry).update?
  end

  # ============================================================
  # DESTROY
  # ============================================================

  test "manager can destroy time entry" do
    assert JobTimeEntryPolicy.new(@manager, @time_entry).destroy?
  end

  test "owner can destroy time entry" do
    assert JobTimeEntryPolicy.new(@owner, @time_entry).destroy?
  end

  test "admin can destroy time entry" do
    assert JobTimeEntryPolicy.new(@admin, @time_entry).destroy?
  end

  test "field worker cannot destroy time entry" do
    assert_not JobTimeEntryPolicy.new(@field_worker, @time_entry).destroy?
  end

  test "member cannot destroy time entry" do
    assert_not JobTimeEntryPolicy.new(@member, @time_entry).destroy?
  end

  test "accountant cannot destroy time entry" do
    assert_not JobTimeEntryPolicy.new(@accountant, @time_entry).destroy?
  end

  test "manager cannot destroy time entry from another organization" do
    assert_not JobTimeEntryPolicy.new(@manager, @other_time_entry).destroy?
  end

  # ============================================================
  # SCOPE
  # ============================================================

  test "scope returns only time entries from user's organization" do
    result = JobTimeEntryPolicy::Scope
      .new(@manager, JobTimeEntry.all)
      .resolve

    assert_equal [@time_entry.id, @manager_entry.id].sort, result.pluck(:id).sort
  end

  test "field worker scope returns only entries from actively assigned jobs" do
    result = JobTimeEntryPolicy::Scope
      .new(@field_worker, JobTimeEntry.all)
      .resolve

    assert_equal [@time_entry.id], result.pluck(:id)
  end

  test "unassigned field worker scope returns no entries" do
    result = JobTimeEntryPolicy::Scope
      .new(@unassigned_worker, JobTimeEntry.all)
      .resolve

    assert_empty result
  end

  test "scope excludes entries with foreign job organization" do
    foreign_job_entry = JobTimeEntry.create!(
      organization: @organization,
      job: @other_job,
      user: @field_worker,
      entry_type: "work",
      started_at: Time.zone.parse("2026-08-25 08:00:00"),
      duration_minutes: 60
    )

    result = JobTimeEntryPolicy::Scope
      .new(@manager, JobTimeEntry.all)
      .resolve

    assert_not_includes result.pluck(:id), foreign_job_entry.id
  end

  test "scope excludes entries with foreign user organization" do
    foreign_user_entry = JobTimeEntry.create!(
      organization: @organization,
      job: @job,
      user: @other_worker,
      entry_type: "work",
      started_at: Time.zone.parse("2026-08-25 08:00:00"),
      duration_minutes: 60
    )

    result = JobTimeEntryPolicy::Scope
      .new(@manager, JobTimeEntry.all)
      .resolve

    assert_not_includes result.pluck(:id), foreign_user_entry.id
  end
end