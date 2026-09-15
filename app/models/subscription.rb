class Subscription < ApplicationRecord
  belongs_to :organization
  belongs_to :plan

  STATUSES = %w[
    trialing
    active
    past_due
    canceled
    incomplete
  ].freeze

  BILLING_INTERVALS = %w[
    monthly
    yearly
  ].freeze

  validates :status,
            presence: true,
            inclusion: { in: STATUSES }

  validates :billing_interval,
            presence: true,
            inclusion: { in: BILLING_INTERVALS }

  validates :stripe_customer_id,
            uniqueness: true,
            allow_nil: true

  validates :stripe_subscription_id,
            uniqueness: true,
            allow_nil: true

  validates :organization_id,
            uniqueness: true

  scope :active, -> { where(status: "active") }
  scope :trialing, -> { where(status: "trialing") }
  scope :canceled, -> { where(status: "canceled") }

  def active?
    status == "active"
  end

  def trialing?
    status == "trialing"
  end

  def canceled?
    status == "canceled"
  end

  def monthly?
    billing_interval == "monthly"
  end

  def yearly?
    billing_interval == "yearly"
  end
end