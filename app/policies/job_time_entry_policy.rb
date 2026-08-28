class JobTimeEntryPolicy < ApplicationPolicy
  def index?
    authenticated?
  end

  def show?
    same_organization? && accessible?
  end

  def create?
    return false unless same_organization?

    management? || assigned_to_job?
  end

  def update?
    return false unless same_organization?

    management? || own_entry_and_assigned_to_job?
  end

  def destroy?
    return false unless same_organization?

    management?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope
        .joins(:job)
        .joins(:user)
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
        .then do |relation|
          if user.field_worker?
            relation
              .joins(
                "INNER JOIN job_assignments ON job_assignments.job_id = job_time_entries.job_id"
              )
              .where(
                job_assignments: {
                  user_id: user.id,
                  active: true
                },
                job_time_entries: {
                  user_id: user.id
                }
              )
          else
            relation
          end
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

  def accessible?
    management? || own_entry_and_assigned_to_job?
  end

  def assigned_to_job?
    record.job.job_assignments.exists?(
      user_id: user.id,
      active: true
    )
  end

  def own_entry_and_assigned_to_job?
    record.user_id == user.id &&
      assigned_to_job?
  end
end