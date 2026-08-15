class Vehicle < ApplicationRecord
  belongs_to :organization

  has_many :jobs

  validates :name, presence: true

  validates :registration_number,
            presence: true,
            uniqueness: { scope: :organization_id }

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
end
