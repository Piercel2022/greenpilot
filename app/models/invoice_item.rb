class InvoiceItem < ApplicationRecord
  belongs_to :invoice
  belongs_to :service_item, optional: true

  validates :description, presence: true
  validates :unit, presence: true

  validates :quantity,
            numericality: { greater_than: 0 }

  validates :unit_price,
            :subtotal,
            :tax_amount,
            :total_amount,
            numericality: { greater_than_or_equal_to: 0 }

  validates :discount_percentage,
            :tax_rate,
            numericality: {
              greater_than_or_equal_to: 0,
              less_than_or_equal_to: 100
            }

  validates :position,
            uniqueness: { scope: :invoice_id }
end