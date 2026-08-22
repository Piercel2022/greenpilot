class QuoteItemPolicy < ApplicationPolicy
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
        .joins(quote: :organization)
        .joins(:service_item)
        .where(
          quotes: {
            organization_id: user.organization_id
          },
          service_items: {
            organization_id: user.organization_id
          }
        )
    end
  end

  private

  def same_organization?
    return false unless authenticated?
    return false unless record.quote
    return false unless record.service_item

    record.quote.organization_id == user.organization_id &&
      record.service_item.organization_id == user.organization_id
  end
end