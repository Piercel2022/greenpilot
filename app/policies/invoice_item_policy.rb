class InvoiceItemPolicy < ApplicationPolicy
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
        .joins(:invoice)
        .left_joins(:service_item)
        .where(
          invoices: {
            organization_id: user.organization_id
          }
        )
        .where(
          "service_items.organization_id IS NULL OR service_items.organization_id = ?",
          user.organization_id
        )
    end
  end

  private

  def same_organization?
    return false unless authenticated?
    return false unless record.invoice

    return false unless record.invoice.organization_id == user.organization_id

    if record.service_item
      return false unless record.service_item.organization_id == user.organization_id
    end

    true
  end
end