class Site < ApplicationRecord
  belongs_to :organization
  belongs_to :customer

  has_many :quotes
  has_many :jobs
  has_many :invoices

  validates :name, presence: true

  validate :customer_belongs_to_organization

  private

  def customer_belongs_to_organization
    return if customer.blank? || organization.blank?

    if customer.organization_id != organization_id
      errors.add(
        :customer,
        "must belong to the same organization"
      )
    end
  end
end
