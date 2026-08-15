class ServiceCategory < ApplicationRecord
  belongs_to :organization

  has_many :service_items

  validates :code, presence: true,
                   uniqueness: { scope: :organization_id }

  validates :name, presence: true

  scope :ordered, -> { order(:position, :name) }
end
