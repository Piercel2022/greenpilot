class JobReportPolicy < ApplicationPolicy
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
    same_organization? && owner_or_admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(organization_id: user.organization_id)
    end
  end

  private

  def same_organization?
    authenticated? &&
      record.organization_id == user.organization_id
  end
end