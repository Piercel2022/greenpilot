
class AdminDashboardPolicy < ApplicationPolicy
  def show?
    authenticated? && user.platform_admin?
  end
end