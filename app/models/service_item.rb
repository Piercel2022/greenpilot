class ServiceItem < ApplicationRecord
  belongs_to :organization
  belongs_to :service_category

  has_many :quote_items
  has_many :invoice_items

  validates :code, presence: true,
                   uniqueness: { scope: :organization_id }

  validates :name, presence: true

  scope :ordered, -> { order(:position, :name) }
end