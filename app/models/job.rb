class Job < ApplicationRecord
  belongs_to :organization
  belongs_to :customer
  belongs_to :site

  belongs_to :quote, optional: true
  belongs_to :team, optional: true
  belongs_to :vehicle, optional: true

  has_many :users, through: :job_assignments

  has_many :job_assignments, dependent: :destroy
  has_many :job_time_entries, dependent: :destroy
  has_many :job_reports, dependent: :destroy

  validates :title, presence: true
  validates :job_type, presence: true

  validates :estimated_duration_minutes,
            numericality: { greater_than_or_equal_to: 0 },
            allow_nil: true

  validates :actual_duration_minutes,
            numericality: { greater_than_or_equal_to: 0 },
            allow_nil: true

  scope :planned, -> { where(status: "planned") }
  scope :by_date, ->(date) { where(scheduled_date: date) }
end