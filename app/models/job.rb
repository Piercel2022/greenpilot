class Job < ApplicationRecord
  # ============================================================
  # ASSOCIATIONS
  # ============================================================

  belongs_to :organization

  belongs_to :customer
  belongs_to :site

  belongs_to :quote, optional: true
  belongs_to :team, optional: true
  belongs_to :vehicle, optional: true

  has_many :job_assignments,
           dependent: :destroy

  has_many :users,
           through: :job_assignments

  has_many :job_time_entries,
           dependent: :destroy

  has_many :job_reports,
           dependent: :destroy
  has_many :invoices, dependent: :destroy
  # ============================================================
  # ENUMS / BUSINESS VALUES
  # ============================================================

  JOB_STATUSES = %w[
    planned
    in_progress
    completed
    cancelled
  ].freeze

  PRIORITIES = %w[
    low
    normal
    high
    urgent
  ].freeze

  WEATHER_RISKS = %w[
    unknown
    low
    medium
    high
  ].freeze

  # ============================================================
  # PRESENCE / BASIC VALIDATIONS
  # ============================================================

  validates :title,
            presence: true

  validates :job_type,
            presence: true

  validates :status,
            presence: true,
            inclusion: { in: JOB_STATUSES }

  validates :priority,
            presence: true,
            inclusion: { in: PRIORITIES }

  validates :weather_risk,
            presence: true,
            inclusion: { in: WEATHER_RISKS }

  # ============================================================
  # DURATION VALIDATIONS
  # ============================================================

  validates :estimated_duration_minutes,
            numericality: {
              greater_than_or_equal_to: 0
            },
            allow_nil: true

  validates :actual_duration_minutes,
            numericality: {
              greater_than_or_equal_to: 0
            },
            allow_nil: true

  validates :travel_duration_minutes,
            numericality: {
              greater_than_or_equal_to: 0
            },
            allow_nil: true

  # ============================================================
  # DISTANCE VALIDATIONS
  # ============================================================

  validates :travel_distance_km,
            numericality: {
              greater_than_or_equal_to: 0
            },
            allow_nil: true

  # ============================================================
  # GPS VALIDATIONS
  # ============================================================

  validates :latitude,
            numericality: {
              greater_than_or_equal_to: -90,
              less_than_or_equal_to: 90
            },
            allow_nil: true

  validates :longitude,
            numericality: {
              greater_than_or_equal_to: -180,
              less_than_or_equal_to: 180
            },
            allow_nil: true

  # ============================================================
  # ORGANIZATION INTEGRITY
  # ============================================================

  validate :customer_belongs_to_organization
  validate :site_belongs_to_organization
  validate :site_belongs_to_customer
  validate :quote_belongs_to_organization
  validate :team_belongs_to_organization
  validate :vehicle_belongs_to_organization

  # ============================================================
  # TEMPORAL INTEGRITY
  # ============================================================

  validate :scheduled_time_range_is_valid
  validate :completion_time_is_valid
  validate :cancellation_time_is_valid
  validate :start_time_is_valid

  # ============================================================
  # STATUS INTEGRITY
  # ============================================================

  validate :completed_job_has_completed_at
  validate :cancelled_job_has_cancelled_at

  # ============================================================
  # SCOPES
  # ============================================================

  scope :planned,
        -> { where(status: "planned") }

  scope :in_progress,
        -> { where(status: "in_progress") }

  scope :completed,
        -> { where(status: "completed") }

  scope :cancelled,
        -> { where(status: "cancelled") }

  scope :by_date,
        ->(date) { where(scheduled_date: date) }

  scope :upcoming,
        -> {
          where(
            "scheduled_date >= ?",
            Date.current
          )
        }

  scope :today,
        -> {
          where(scheduled_date: Date.current)
        }

  scope :this_week,
        -> {
          where(
            scheduled_date: Date.current.beginning_of_week..Date.current.end_of_week
          )
        }

  scope :high_priority,
        -> {
          where(priority: %w[high urgent])
        }

  scope :with_weather_risk,
        -> {
          where(weather_risk: %w[medium high])
        }

  # ============================================================
  # PRIVATE VALIDATIONS
  # ============================================================

  private

  # ------------------------------------------------------------
  # Customer
  # ------------------------------------------------------------

  def customer_belongs_to_organization
    return if organization.blank? || customer.blank?

    unless customer.organization_id == organization_id
      errors.add(
        :customer,
        "must belong to the same organization"
      )
    end
  end

  # ------------------------------------------------------------
  # Site organization
  # ------------------------------------------------------------

  def site_belongs_to_organization
    return if organization.blank? || site.blank?

    unless site.organization_id == organization_id
      errors.add(
        :site,
        "must belong to the same organization"
      )
    end
  end

  # ------------------------------------------------------------
  # Site ↔ Customer
  # ------------------------------------------------------------

  def site_belongs_to_customer
    return if customer.blank? || site.blank?

    unless site.customer_id == customer_id
      errors.add(
        :site,
        "must belong to the selected customer"
      )
    end
  end

  # ------------------------------------------------------------
  # Quote organization
  # ------------------------------------------------------------

  def quote_belongs_to_organization
    return if organization.blank? || quote.blank?

    unless quote.organization_id == organization_id
      errors.add(
        :quote,
        "must belong to the same organization"
      )
    end
  end

  # ------------------------------------------------------------
  # Team organization
  # ------------------------------------------------------------

  def team_belongs_to_organization
    return if organization.blank? || team.blank?

    unless team.organization_id == organization_id
      errors.add(
        :team,
        "must belong to the same organization"
      )
    end
  end

  # ------------------------------------------------------------
  # Vehicle organization
  # ------------------------------------------------------------

  def vehicle_belongs_to_organization
    return if organization.blank? || vehicle.blank?

    unless vehicle.organization_id == organization_id
      errors.add(
        :vehicle,
        "must belong to the same organization"
      )
    end
  end

  # ============================================================
  # TEMPORAL VALIDATIONS
  # ============================================================

  def scheduled_time_range_is_valid
    return if scheduled_start_at.blank? || scheduled_end_at.blank?

    if scheduled_end_at < scheduled_start_at
      errors.add(
        :scheduled_end_at,
        "must be after scheduled start time"
      )
    end
  end

  def start_time_is_valid
    return if started_at.blank? || scheduled_start_at.blank?

    if started_at < scheduled_start_at
      errors.add(
        :started_at,
        "cannot be before scheduled start time"
      )
    end
  end

  def completion_time_is_valid
    return if completed_at.blank? || started_at.blank?

    if completed_at < started_at
      errors.add(
        :completed_at,
        "cannot be before started time"
      )
    end
  end

  def cancellation_time_is_valid
    return if cancelled_at.blank?

    if started_at.present? && cancelled_at < started_at
      errors.add(
        :cancelled_at,
        "cannot be before started time"
      )
    end
  end

  # ============================================================
  # STATUS VALIDATIONS
  # ============================================================

  def completed_job_has_completed_at
    return unless status == "completed"

    if completed_at.blank?
      errors.add(
        :completed_at,
        "must be present when job is completed"
      )
    end
  end

  def cancelled_job_has_cancelled_at
    return unless status == "cancelled"

    if cancelled_at.blank?
      errors.add(
        :cancelled_at,
        "must be present when job is cancelled"
      )
    end
  end
end
