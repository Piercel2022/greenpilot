require "test_helper"

class QuoteTest < ActiveSupport::TestCase
  setup do
    @organization = Organization.create!(name: "GreenPilot Quote Test", slug: "greenpilot-quote-test")

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

  test "belongs to organization customer and site" do
    assert_equal :belongs_to, Quote.reflect_on_association(:organization).macro
    assert_equal :belongs_to, Quote.reflect_on_association(:customer).macro
    assert_equal :belongs_to, Quote.reflect_on_association(:site).macro
  end

  test "has quote items jobs and invoices" do
    assert_equal :has_many, Quote.reflect_on_association(:quote_items).macro
    assert_equal :has_many, Quote.reflect_on_association(:jobs).macro
    assert_equal :has_many, Quote.reflect_on_association(:invoices).macro
  end

  test "requires number title and issue date" do
    quote = Quote.new(
      organization: @organization,
      customer: @customer,
      site: @site
    )

    refute quote.valid?
    assert quote.errors[:number].any?
    assert quote.errors[:title].any?
    assert quote.errors[:issue_date].any?
  end

  test "number is unique within organization" do
    Quote.create!(
      organization: @organization,
      customer: @customer,
      site: @site,
      number: "DEV-001",
      title: "Garden Maintenance",
      issue_date: Date.current
    )

    duplicate = Quote.new(
      organization: @organization,
      customer: @customer,
      site: @site,
      number: "DEV-001",
      title: "Another Quote",
      issue_date: Date.current
    )

    refute duplicate.valid?
    assert duplicate.errors[:number].any?
  end
end
