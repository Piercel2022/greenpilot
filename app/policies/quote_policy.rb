class QuotePolicy < ApplicationPolicy
  def index?
    authenticated?
  end

  def show?
    same_organization?
  end

  def create?
    management?
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
        .joins(:customer, :site)
        .where(
          quotes: {
            organization_id: user.organization_id
          },
          customers: {
            organization_id: user.organization_id
          },
          sites: {
            organization_id: user.organization_id
          }
        )
    end
  end

  private

  def same_organization?
    return false unless authenticated?
    return false unless record.organization
    return false unless record.customer
    return false unless record.site

    return false unless record.organization_id == user.organization_id
    return false unless record.customer.organization_id == user.organization_id
    return false unless record.site.organization_id == user.organization_id

    true
  end
end