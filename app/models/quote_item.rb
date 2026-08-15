class QuoteItem < ApplicationRecord
  belongs_to :quote
  belongs_to :service_item

  validates :description, presence: true

  validates :quantity,
            numericality: { greater_than: 0 }

  validates :unit_price,
            numericality: { greater_than_or_equal_to: 0 }

  validates :discount_percentage,
            numericality: {
              greater_than_or_equal_to: 0,
              less_than_or_equal_to: 100
            }

  validates :tax_rate,
            numericality: {
              greater_than_or_equal_to: 0,
              less_than_or_equal_to: 100
            }

  scope :ordered, -> { order(:position) }
end