require "test_helper"

class QuoteItemTest < ActiveSupport::TestCase
  setup do
    @organization = Organization.create!(name: "GreenPilot Quote Item Test", slug: "greenpilot-quote-item-test")

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

    @category = ServiceCategory.create!(
      organization: @organization,
      code: "ENT",
      name: "Entretien"
    )

    @service_item = ServiceItem.create!(
      organization: @organization,
      service_category: @category,
      code: "TONTE",
      name: "Tonte"
    )

    @quote = Quote.create!(
      organization: @organization,
      customer: @customer,
      site: @site,
      number: "DEV-001",
      title: "Garden Maintenance",
      issue_date: Date.current
    )
  end

  test "belongs to quote and service item" do
    assert_equal :belongs_to, QuoteItem.reflect_on_association(:quote).macro
    assert_equal :belongs_to, QuoteItem.reflect_on_association(:service_item).macro
  end

  test "requires description" do
    item = QuoteItem.new(
      quote: @quote,
      service_item: @service_item
    )

    refute item.valid?
    assert item.errors[:description].any?
  end

  test "quantity must be greater than zero" do
    item = QuoteItem.new(
      quote: @quote,
      service_item: @service_item,
      description: "Tonte",
      quantity: 0
    )

    refute item.valid?
    assert item.errors[:quantity].any?
  end

  test "discount percentage must be between zero and one hundred" do
    item = QuoteItem.new(
      quote: @quote,
      service_item: @service_item,
      description: "Tonte",
      discount_percentage: 101
    )

    refute item.valid?
    assert item.errors[:discount_percentage].any?
  end

  test "tax rate must be between zero and one hundred" do
    item = QuoteItem.new(
      quote: @quote,
      service_item: @service_item,
      description: "Tonte",
      tax_rate: 101
    )

    refute item.valid?
    assert item.errors[:tax_rate].any?
  end

  test "ordered scope sorts by position" do
    QuoteItem.create!(
      quote: @quote,
      service_item: @service_item,
      description: "Second",
      position: 2
    )

    second_service_item = ServiceItem.create!(
      organization: @organization,
      service_category: @category,
      code: "TAILLE",
      name: "Taille"
    )

    QuoteItem.create!(
      quote: @quote,
      service_item: second_service_item,
      description: "First",
      position: 1
    )

    assert_equal [1, 2], @quote.quote_items.ordered.pluck(:position)
  end
end
