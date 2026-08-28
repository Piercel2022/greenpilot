ENV["RAILS_ENV"] ||= "test"

require_relative "../config/environment"
require "rails/test_help"
require_relative "support/test_helpers"

class ActiveSupport::TestCase
  include TestHelpers

  fixtures :organizations, :users, :customers, :sites, :teams,
           :team_memberships, :vehicles, :equipment,
           :service_categories, :service_items, :quotes,
           :quote_items, :jobs, :job_reports, :job_assignments, :invoices,
           :invoice_items
end