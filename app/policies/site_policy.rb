class SitePolicy < ApplicationPolicy
  def index?
    authenticated?
  end

  def show?
    same_organization?
  end

  def create?
    management? && customer_same_organization?
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

  def customer_same_organization?
    return false unless record.customer
    return false unless record.organization_id == user.organization_id

    record.customer.organization_id == user.organization_id
  end
end