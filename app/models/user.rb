class User < ApplicationRecord
  belongs_to :organization

  has_many :team_memberships
  has_many :teams, through: :team_memberships

  has_many :job_assignments
  has_many :jobs, through: :job_assignments

  has_many :job_time_entries
end