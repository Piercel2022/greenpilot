class ServiceItemPolicy < ApplicationPolicy
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
      scope
        .joins(:service_category)
        .where(
          service_items: {
            organization_id: user.organization_id
          },
          service_categories: {
            organization_id: user.organization_id
          }
        )
    end
  end

  private

  def same_organization?
    return false unless authenticated?
    return false unless record.organization
    return false unless record.service_category

    record.organization_id == user.organization_id &&
      record.service_category.organization_id == user.organization_id
  end
end