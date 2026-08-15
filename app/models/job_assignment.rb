class JobAssignment < ApplicationRecord
  belongs_to :organization
  belongs_to :job
  belongs_to :user

  validates :assignment_type, presence: true
  validates :role, presence: true

  validates :user_id,
            uniqueness: { scope: :job_id }

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
end
