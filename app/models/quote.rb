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

  validate :customer_belongs_to_organization
  validate :site_belongs_to_organization
  validate :site_belongs_to_customer

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

  def site_belongs_to_organization
    return if site.blank? || organization.blank?

    if site.organization_id != organization_id
      errors.add(
        :site,
        "must belong to the same organization"
      )
    end
  end

  def site_belongs_to_customer
    return if site.blank? || customer.blank?

    if site.customer_id != customer_id
      errors.add(
        :site,
        "must belong to the selected customer"
      )
    end
  end
end