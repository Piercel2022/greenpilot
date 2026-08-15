class Organization < ApplicationRecord
  has_many :users

  has_many :customers
  has_many :sites

  has_many :service_categories
  has_many :service_items

  has_many :quotes
  has_many :quote_items, through: :quotes

  has_many :teams
  has_many :team_memberships

  has_many :vehicles
  has_many :equipment

  has_many :jobs
  has_many :job_assignments
  has_many :job_time_entries
  has_many :job_reports

  has_many :invoices
  has_many :invoice_items, through: :invoices
end
