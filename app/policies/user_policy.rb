class UserPolicy < ApplicationPolicy
  def index?
    management?
  end

  def show?
    same_organization? && management?
  end

  def create?
    management?
  end

  def update?
    return false unless same_organization?

    owner? || admin?
  end

  def destroy?
    return false unless same_organization?

    owner?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(organization_id: user.organization_id)
    end
  end
end