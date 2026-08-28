class TeamMembership < ApplicationRecord
  belongs_to :organization
  belongs_to :team
  belongs_to :user

  validates :role, presence: true

  validates :user_id,
            uniqueness: { scope: :team_id }

  validate :team_belongs_to_organization
  validate :user_belongs_to_organization

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }

  private

  def team_belongs_to_organization
    return if organization.blank? || team.blank?

    if team.organization_id != organization_id
      errors.add(
        :team,
        "must belong to the same organization"
      )
    end
  end

  def user_belongs_to_organization
    return if organization.blank? || user.blank?

    if user.organization_id != organization_id
      errors.add(
        :user,
        "must belong to the same organization"
      )
    end
  end
end
