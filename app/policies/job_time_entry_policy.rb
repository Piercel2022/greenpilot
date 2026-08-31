class JobTimeEntryPolicy < ApplicationPolicy
  def index?
    authenticated?
  end

  def show?
    return false unless authenticated?
    return false unless same_organization?

    if management?
      true
    elsif field_worker?
      own_entry? && actively_assigned?
    else
      false
    end
  end

  def create?
    return false unless authenticated?
    return false unless same_organization?

    if management?
      true
    elsif field_worker?
      own_entry? && actively_assigned?
    else
      false
    end
  end

  def update?
    return false unless authenticated?
    return false unless same_organization?

    if management?
      true
    elsif field_worker?
      own_entry? && actively_assigned?
    else
      false
    end
  end

  def destroy?
    same_organization? && management?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      base_scope =
        scope
        .joins(:job, :user)
        .where(
          job_time_entries: {
            organization_id: user.organization_id
          },
          jobs: {
            organization_id: user.organization_id
          },
          users: {
            organization_id: user.organization_id
          }
        )

      if user.owner? || user.admin? || user.manager?
        base_scope
      elsif user.field_worker?
        base_scope
          .joins(
            "INNER JOIN job_assignments
             ON job_assignments.job_id = job_time_entries.job_id
             AND job_assignments.user_id = job_time_entries.user_id
             AND job_assignments.active = TRUE"
          )
          .where(
            job_time_entries: {
              user_id: user.id
            },
            job_assignments: {
              organization_id: user.organization_id
            }
          )
      else
        scope.none
      end
    end
  end

  private

  def same_organization?
    return false unless authenticated?
    return false unless record.organization
    return false unless record.job
    return false unless record.user

    record.organization_id == user.organization_id &&
      record.job.organization_id == user.organization_id &&
      record.user.organization_id == user.organization_id
  end

  def own_entry?
    record.user_id == user.id
  end

  def actively_assigned?
    return false unless record.job

    JobAssignment.exists?(
      organization_id: user.organization_id,
      job_id: record.job_id,
      user_id: user.id,
      active: true
    )
  end
end