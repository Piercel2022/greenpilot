class Team < ApplicationRecord
  belongs_to :organization

  has_many :team_memberships
  has_many :users, through: :team_memberships

  has_many :jobs

  validates :code,
            presence: true,
            uniqueness: { scope: :organization_id }

  validates :name, presence: true
end