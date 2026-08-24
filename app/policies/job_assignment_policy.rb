class JobAssignmentPolicy < ApplicationPolicy
  def index?
    authenticated?
  end

  def show?
    same_organization?
  end

  def create?
    same_organization? && management?
  end

  def update?
    same_organization? && management?
  end

  def destroy?
    same_organization? && management?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope
        .joins(:job, :user)
        .where(
          job_assignments: {
            organization_id: user.organization_id
          },
          jobs: {
            organization_id: user.organization_id
          },
          users: {
            organization_id: user.organization_id
          }
        )
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
end