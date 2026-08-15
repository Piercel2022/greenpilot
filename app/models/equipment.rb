class Equipment < ApplicationRecord
  belongs_to :organization

  enum :status, {
    available: "available",
    in_use: "in_use",
    maintenance: "maintenance",
    out_of_service: "out_of_service",
    retired: "retired"
  }

  validates :name, presence: true
  validates :equipment_type, presence: true

  validates :serial_number,
            uniqueness: { scope: :organization_id },
            allow_nil: true

  validates :purchase_price,
            numericality: { greater_than_or_equal_to: 0 },
            allow_nil: true

  validates :maintenance_interval_days,
            numericality: { greater_than: 0 },
            allow_nil: true

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
end