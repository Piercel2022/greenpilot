class JobReport < ApplicationRecord
  belongs_to :organization
  belongs_to :job

  validate :job_belongs_to_organization

  scope :generated, -> { where.not(generated_at: nil) }
  scope :not_generated, -> { where(generated_at: nil) }

  scope :sent, -> { where.not(sent_to_customer_at: nil) }
  scope :not_sent, -> { where(sent_to_customer_at: nil) }

  scope :signed, -> { where.not(customer_signed_at: nil) }
  scope :unsigned, -> { where(customer_signed_at: nil) }

  private

  def job_belongs_to_organization
    return if organization.blank? || job.blank?

    unless job.organization_id == organization_id
      errors.add(
        :job,
        "must belong to the same organization"
      )
    end
  end
end