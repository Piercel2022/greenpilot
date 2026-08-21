class OrganizationPolicy < ApplicationPolicy
  def show?
    same_organization?
  end

  def update?
    same_organization? && owner_or_admin?
  end

  def destroy?
    same_organization? && owner?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(id: user.organization_id)
    end
  end

  private

  def same_organization?
    authenticated? && record.id == user.organization_id
  end
end