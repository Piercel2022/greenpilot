class ServiceItem < ApplicationRecord
  belongs_to :organization
  belongs_to :service_category

  has_many :quote_items
  has_many :invoice_items

  validates :code, presence: true,
                   uniqueness: { scope: :organization_id }

  validates :name, presence: true

  validate :service_category_belongs_to_organization

  scope :ordered, -> { order(:position, :name) }

  private

  def service_category_belongs_to_organization
    return if service_category.blank? || organization.blank?

    if service_category.organization_id != organization_id
      errors.add(
        :service_category,
        "must belong to the same organization"
      )
    end
  end
end
