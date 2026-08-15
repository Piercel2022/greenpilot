class Quote < ApplicationRecord
  belongs_to :organization
  belongs_to :customer
  belongs_to :site

  has_many :quote_items

  has_many :jobs
  has_many :invoices

  validates :number, presence: true,
                     uniqueness: { scope: :organization_id }

  validates :title, presence: true
  validates :issue_date, presence: true
end