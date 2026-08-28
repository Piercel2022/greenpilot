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

  validate :service_item_belongs_to_quote_organization
  validate :quote_belongs_to_organization

  scope :ordered, -> { order(:position) }

  private

  def service_item_belongs_to_quote_organization
    return if quote.blank? || service_item.blank?

    if service_item.organization_id != quote.organization_id
      errors.add(
        :service_item,
        "must belong to the same organization as the quote"
      )
    end
  end

  def quote_belongs_to_organization
    return if quote.blank? || service_item.blank?

    if quote.organization_id != service_item.organization_id
      errors.add(
        :quote,
        "must belong to the same organization"
      )
    end
  end
end
