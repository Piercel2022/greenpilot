class Plan < ApplicationRecord
  has_many :subscriptions, dependent: :restrict_with_exception

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  validates :monthly_price_cents,
            numericality: { greater_than_or_equal_to: 0 }

  validates :yearly_price_cents,
            numericality: { greater_than_or_equal_to: 0 }

  validates :max_users,
            numericality: { greater_than: 0 }

  scope :active, -> { where(active: true) }
end