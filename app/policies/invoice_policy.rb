class InvoicePolicy < ApplicationPolicy
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
    return false unless same_organization?

    management? || accountant?
  end

  def destroy?
    same_organization? && owner_or_admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope
        .joins(:customer)
        .left_joins(:job, :quote, :site)
        .where(
          invoices: {
            organization_id: user.organization_id
          },
          customers: {
            organization_id: user.organization_id
          }
        )
        .where(
          "jobs.organization_id IS NULL OR jobs.organization_id = ?",
          user.organization_id
        )
        .where(
          "quotes.organization_id IS NULL OR quotes.organization_id = ?",
          user.organization_id
        )
        .where(
          "sites.organization_id IS NULL OR sites.organization_id = ?",
          user.organization_id
        )
    end
  end

  private

  def same_organization?
    return false unless authenticated?
    return false unless record.organization
    return false unless record.customer

    return false unless record.organization_id == user.organization_id
    return false unless record.customer.organization_id == user.organization_id

    if record.job
      return false unless record.job.organization_id == user.organization_id
    end

    if record.quote
      return false unless record.quote.organization_id == user.organization_id
    end

    if record.site
      return false unless record.site.organization_id == user.organization_id
    end

    true
  end
end