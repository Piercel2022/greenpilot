class JobTimeEntry < ApplicationRecord
  belongs_to :organization
  belongs_to :job
  belongs_to :user

  validates :started_at, presence: true
  validates :entry_type, presence: true

  validates :duration_minutes,
            numericality: { greater_than_or_equal_to: 0 },
            allow_nil: true
end