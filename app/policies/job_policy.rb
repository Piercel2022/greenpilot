class JobPolicy < ApplicationPolicy
  def index?
    authenticated?
  end

  def show?
    same_organization?
  end

  def create?
    same_organization? && management?
  end

  def create_base?
    authenticated? && management?
  end

  def update?
    return false unless same_organization?

    management? || assigned_field_worker?
  end

  def destroy?
    same_organization? && owner_or_admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope
        .joins(:customer, :site)
        .left_joins(:quote, :team, :vehicle)
        .where(
          jobs: {
            organization_id: user.organization_id
          },
          customers: {
            organization_id: user.organization_id
          },
          sites: {
            organization_id: user.organization_id
          }
        )
        .where(
          "quotes.organization_id IS NULL OR quotes.organization_id = ?",
          user.organization_id
        )
        .where(
          "teams.organization_id IS NULL OR teams.organization_id = ?",
          user.organization_id
        )
        .where(
          "vehicles.organization_id IS NULL OR vehicles.organization_id = ?",
          user.organization_id
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

    if record.quote
      return false unless record.quote.organization_id == user.organization_id
    end

    if record.team
      return false unless record.team.organization_id == user.organization_id
    end

    if record.vehicle
      return false unless record.vehicle.organization_id == user.organization_id
    end

    true
  end

  def assigned_field_worker?
    return false unless field_worker?

    record.job_assignments.exists?(
      user_id: user.id,
      active: true
    )
  end
end
