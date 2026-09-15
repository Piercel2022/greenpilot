
class Organization < ApplicationRecord

  has_one :subscription, dependent: :destroy
  has_many :users

  has_many :customers
  has_many :sites

  has_many :service_categories
  has_many :service_items

  has_many :quotes
  has_many :quote_items, through: :quotes

  has_many :teams
  has_many :team_memberships

  has_many :vehicles
  has_many :equipment

  has_many :jobs
  has_many :job_assignments
  has_many :job_time_entries
  has_many :job_reports

  has_many :invoices
  has_many :invoice_items, through: :invoices

  before_validation :generate_slug, on: :create

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  private

  def generate_slug
    return if name.blank?

    base_slug = name.to_s.parameterize
    self.slug = base_slug if slug.blank?

    return unless Organization.exists?(slug: slug)

    suffix = 2

    loop do
      candidate = "#{base_slug}-#{suffix}"

      unless Organization.exists?(slug: candidate)
        self.slug = candidate
        break
      end

      suffix += 1
    end
  end
end