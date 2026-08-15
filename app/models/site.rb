class Site < ApplicationRecord
  belongs_to :organization
  belongs_to :customer

  has_many :quotes
  has_many :jobs
  has_many :invoices

  validates :name, presence: true
end