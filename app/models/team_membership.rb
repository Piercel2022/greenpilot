class TeamMembership < ApplicationRecord
  belongs_to :organization
  belongs_to :team
  belongs_to :user

  validates :role, presence: true

  validates :user_id,
            uniqueness: { scope: :team_id }

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
end