class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      raise NotImplementedError
    end
  end

  private

  def authenticated?
    user.present?
  end

  def same_organization?
    return false unless authenticated?
    return false unless record.respond_to?(:organization_id)

    user.organization_id == record.organization_id
  end

  def owner?
    user.owner?
  end

  def admin?
    user.admin?
  end

  def manager?
    user.manager?
  end

  def accountant?
    user.accountant?
  end

  def field_worker?
    user.field_worker?
  end

  def member?
    user.member?
  end

  def owner_or_admin?
    owner? || admin?
  end

  def owner_admin_or_manager?
    owner? || admin? || manager?
  end

  def management?
    owner? || admin? || manager?
  end
end