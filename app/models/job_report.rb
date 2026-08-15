class JobReport < ApplicationRecord
  belongs_to :organization
  belongs_to :job

  scope :generated, -> { where.not(generated_at: nil) }
  scope :not_generated, -> { where(generated_at: nil) }

  scope :sent, -> { where.not(sent_to_customer_at: nil) }
  scope :not_sent, -> { where(sent_to_customer_at: nil) }

  scope :signed, -> { where.not(customer_signed_at: nil) }
  scope :unsigned, -> { where(customer_signed_at: nil) }
end