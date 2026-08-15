class Invoice < ApplicationRecord
  belongs_to :organization
  belongs_to :customer

  belongs_to :job, optional: true
  belongs_to :quote, optional: true
  belongs_to :site, optional: true

  has_many :invoice_items
end