
require "test_helper"

class JobReportPolicyTest < ActiveSupport::TestCase
  # ============================================================
  # INDEX
  # ============================================================

  test "authenticated user can list job reports" do
    user = users(:member_a)

    assert JobReportPolicy.new(user, JobReport).index?
  end

  # ============================================================
  # SHOW
  # ============================================================

  test "user can view job report from same organization" do
    user = users(:member_a)
    report = job_reports(:job_report_a)

    assert JobReportPolicy.new(user, report).show?
  end

  test "user cannot view job report from another organization" do
    user = users(:member_a)
    report = job_reports(:job_report_b)

    assert_not JobReportPolicy.new(user, report).show?
  end

  test "user cannot view job report with foreign job" do
    user = users(:member_a)
    report = job_reports(:job_report_a)

    report.job = jobs(:job_b)

    assert_not JobReportPolicy.new(user, report).show?
  end

  # ============================================================
  # CREATE
  # ============================================================

  test "manager can create job report" do
    user = users(:manager_a)

    report = JobReport.new(
      organization: user.organization,
      job: jobs(:job_a)
    )

    assert JobReportPolicy.new(user, report).create?
  end

  test "admin can create job report" do
    user = users(:admin_a)

    report = JobReport.new(
      organization: user.organization,
      job: jobs(:job_a)
    )

    assert JobReportPolicy.new(user, report).create?
  end

  test "owner can create job report" do
    user = users(:owner_a)

    report = JobReport.new(
      organization: user.organization,
      job: jobs(:job_a)
    )

    assert JobReportPolicy.new(user, report).create?
  end

  test "member cannot create job report" do
    user = users(:member_a)

    report = JobReport.new(
      organization: user.organization,
      job: jobs(:job_a)
    )

    assert_not JobReportPolicy.new(user, report).create?
  end

  test "field worker cannot create job report" do
    user = users(:field_worker_a)

    report = JobReport.new(
      organization: user.organization,
      job: jobs(:job_a)
    )

    assert_not JobReportPolicy.new(user, report).create?
  end

  test "accountant cannot create job report" do
    user = users(:accountant_a)

    report = JobReport.new(
      organization: user.organization,
      job: jobs(:job_a)
    )

    assert_not JobReportPolicy.new(user, report).create?
  end

  test "manager cannot create job report for foreign organization" do
    user = users(:manager_a)

    report = JobReport.new(
      organization: user.organization,
      job: jobs(:job_b)
    )

    assert_not JobReportPolicy.new(user, report).create?
  end

  # ============================================================
  # UPDATE
  # ============================================================

  test "manager can update job report" do
    user = users(:manager_a)
    report = job_reports(:job_report_a)

    assert JobReportPolicy.new(user, report).update?
  end

  test "admin can update job report" do
    user = users(:admin_a)
    report = job_reports(:job_report_a)

    assert JobReportPolicy.new(user, report).update?
  end

  test "owner can update job report" do
    user = users(:owner_a)
    report = job_reports(:job_report_a)

    assert JobReportPolicy.new(user, report).update?
  end

  test "member cannot update job report" do
    user = users(:member_a)
    report = job_reports(:job_report_a)

    assert_not JobReportPolicy.new(user, report).update?
  end

  test "field worker cannot update job report" do
    user = users(:field_worker_a)
    report = job_reports(:job_report_a)

    assert_not JobReportPolicy.new(user, report).update?
  end

  test "accountant cannot update job report" do
    user = users(:accountant_a)
    report = job_reports(:job_report_a)

    assert_not JobReportPolicy.new(user, report).update?
  end

  test "manager cannot update job report from another organization" do
    user = users(:manager_a)
    report = job_reports(:job_report_b)

    assert_not JobReportPolicy.new(user, report).update?
  end

  test "manager cannot update job report with foreign job" do
    user = users(:manager_a)
    report = job_reports(:job_report_a)

    report.job = jobs(:job_b)

    assert_not JobReportPolicy.new(user, report).update?
  end

  # ============================================================
  # DESTROY
  # ============================================================

  test "owner can destroy job report" do
    user = users(:owner_a)
    report = job_reports(:job_report_a)

    assert JobReportPolicy.new(user, report).destroy?
  end

  test "admin can destroy job report" do
    user = users(:admin_a)
    report = job_reports(:job_report_a)

    assert JobReportPolicy.new(user, report).destroy?
  end

  test "manager cannot destroy job report" do
    user = users(:manager_a)
    report = job_reports(:job_report_a)

    assert_not JobReportPolicy.new(user, report).destroy?
  end

  test "member cannot destroy job report" do
    user = users(:member_a)
    report = job_reports(:job_report_a)

    assert_not JobReportPolicy.new(user, report).destroy?
  end

  test "field worker cannot destroy job report" do
    user = users(:field_worker_a)
    report = job_reports(:job_report_a)

    assert_not JobReportPolicy.new(user, report).destroy?
  end

  test "accountant cannot destroy job report" do
    user = users(:accountant_a)
    report = job_reports(:job_report_a)

    assert_not JobReportPolicy.new(user, report).destroy?
  end

  test "owner cannot destroy job report from another organization" do
    user = users(:owner_a)
    report = job_reports(:job_report_b)

    assert_not JobReportPolicy.new(user, report).destroy?
  end

  # ============================================================
  # SCOPE
  # ============================================================

  test "scope returns job reports from user's organization only" do
    user = users(:member_a)

    reports = JobReportPolicy::Scope
      .new(user, JobReport.all)
      .resolve

    assert_includes reports, job_reports(:job_report_a)
    assert_not_includes reports, job_reports(:job_report_b)
  end

  test "scope excludes job report whose job belongs to another organization" do
    user = users(:member_a)
    report = job_reports(:job_report_a)

    report.update_column(:job_id, jobs(:job_b).id)

    reports = JobReportPolicy::Scope
      .new(user, JobReport.all)
      .resolve

    assert_not_includes reports, report
  end

  test "scope excludes job report whose organization differs from user's organization" do
    user = users(:member_a)

    report = job_reports(:job_report_a)
    report.update_column(:organization_id, organizations(:organization_b).id)

    reports = JobReportPolicy::Scope
      .new(user, JobReport.all)
      .resolve

    assert_not_includes reports, report
  end

  # ============================================================
  # ORGANIZATION INTEGRITY
  # ============================================================

  test "same organization requires report and job to belong to user's organization" do
    user = users(:manager_a)
    report = job_reports(:job_report_a)

    report.organization_id = user.organization_id
    report.job = jobs(:job_b)

    assert_not JobReportPolicy.new(user, report).show?
    assert_not JobReportPolicy.new(user, report).create?
    assert_not JobReportPolicy.new(user, report).update?
    assert_not JobReportPolicy.new(user, report).destroy?
  end
end