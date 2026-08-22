ENV["RAILS_ENV"] ||= "test"

require_relative "../config/environment"
require "rails/test_help"

class ActiveSupport::TestCase
  fixtures :organizations, :users, :customers, :sites, :teams, :team_memberships, :vehicles, :equipment, :service_categories, :service_items, :quotes,:quote_items,:jobs,:job_assignments,:invoices, :invoice_items
end