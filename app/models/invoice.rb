class Invoice < ApplicationRecord
  belongs_to :organization
  belongs_to :customer

  belongs_to :job, optional: true
  belongs_to :quote, optional: true
  belongs_to :site, optional: true

  has_many :invoice_items, dependent: :destroy

  validates :number, presence: true
  validates :issue_date, presence: true

  validates :number,
            uniqueness: { scope: :organization_id }

  validates :subtotal,
            numericality: { greater_than_or_equal_to: 0 }

  validates :discount_amount,
            numericality: { greater_than_or_equal_to: 0 }

  validates :tax_amount,
            numericality: { greater_than_or_equal_to: 0 }

  validates :total_amount,
            numericality: { greater_than_or_equal_to: 0 }

  validates :amount_paid,
            numericality: { greater_than_or_equal_to: 0 }

  validates :amount_due,
            numericality: { greater_than_or_equal_to: 0 }
end