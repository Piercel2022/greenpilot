class ContactRequest < ApplicationRecord
  STATUSES = %w[
    new
    contacted
    qualified
    converted
    closed
  ].freeze

  REQUEST_TYPES = [
    "Découvrir GreenPilot",
    "Demander une démonstration",
    "Poser une question",
    "Informations tarifaires",
    "Support",
    "Autre"
  ].freeze

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, presence: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :company, presence: true
  validates :request_type, presence: true,
                           inclusion: { in: REQUEST_TYPES }
  validates :message, presence: true
  validates :status, presence: true,
                     inclusion: { in: STATUSES }

  before_validation :set_default_status, on: :create

  scope :new_requests, -> { where(status: "new") }
  scope :contacted, -> { where(status: "contacted") }
  scope :qualified, -> { where(status: "qualified") }
  scope :converted, -> { where(status: "converted") }
  scope :closed, -> { where(status: "closed") }

  private

  def set_default_status
    self.status ||= "new"
  end
end