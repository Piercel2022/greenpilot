class User < ApplicationRecord
  has_secure_password

  belongs_to :organization

  has_many :team_memberships
  has_many :teams, through: :team_memberships

  has_many :job_assignments
  has_many :jobs, through: :job_assignments

  has_many :job_time_entries

  enum :role, {
    member: "member",
    field_worker: "field_worker",
    accountant: "accountant",
    manager: "manager",
    admin: "admin",
    owner: "owner"
  }
end