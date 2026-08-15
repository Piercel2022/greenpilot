class Customer < ApplicationRecord
  belongs_to :organization

  has_many :sites
  has_many :quotes
  has_many :jobs
  has_many :invoices

  enum :customer_type, {
    individual: "individual",
    company: "company"
  }, validate: true
end