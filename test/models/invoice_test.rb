require "test_helper"

class InvoiceTest < ActiveSupport::TestCase
  setup do
    @organization = Organization.create!(name: "GreenPilot Invoice Test", slug: "greenpilot-invoice-test")

    @customer = Customer.create!(
      organization: @organization,
      first_name: "John",
      last_name: "Customer"
    )

    @site = Site.create!(
      organization: @organization,
      customer: @customer,
      name: "Customer Site"
    )
  end

  test "belongs to organization and customer" do
    assert_equal :belongs_to, Invoice.reflect_on_association(:organization).macro
    assert_equal :belongs_to, Invoice.reflect_on_association(:customer).macro
  end

  test "job quote and site associations are optional" do
    assert Invoice.reflect_on_association(:job).options[:optional]
    assert Invoice.reflect_on_association(:quote).options[:optional]
    assert Invoice.reflect_on_association(:site).options[:optional]
  end

  test "has invoice items" do
    assert_equal :has_many, Invoice.reflect_on_association(:invoice_items).macro
  end

  test "can be created with only required associations" do
    invoice = Invoice.new(
      organization: @organization,
      customer: @customer,
      issue_date: Date.current,
      number: "FAC-001"
    )

    assert invoice.valid?
  end
end
