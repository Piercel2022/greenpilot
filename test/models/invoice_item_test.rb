require "test_helper"

class InvoiceItemTest < ActiveSupport::TestCase
  setup do
    @organization = Organization.create!(name: "GreenPilot Invoice Item Test", slug: "greenpilot-invoice-item-test")

    @customer = Customer.create!(
      organization: @organization,
      first_name: "John",
      last_name: "Customer"
    )

    @invoice = Invoice.create!(
      organization: @organization,
      customer: @customer,
      issue_date: Date.current,
      number: "FAC-001"
    )
  end

  test "belongs to invoice" do
    assert_equal :belongs_to, InvoiceItem.reflect_on_association(:invoice).macro
  end

  test "service item association is optional" do
    association = InvoiceItem.reflect_on_association(:service_item)

    assert_equal :belongs_to, association.macro
    assert association.options[:optional]
  end

  test "requires description and unit" do
    item = InvoiceItem.new(invoice: @invoice)

    refute item.valid?
    assert item.errors[:description].any?
    assert item.errors[:unit].any?
  end

  test "quantity must be greater than zero" do
    item = InvoiceItem.new(
      invoice: @invoice,
      description: "Tonte",
      unit: "unit",
      quantity: 0
    )

    refute item.valid?
    assert item.errors[:quantity].any?
  end

  test "amounts cannot be negative" do
    item = InvoiceItem.new(
      invoice: @invoice,
      description: "Tonte",
      unit: "unit",
      unit_price: -1
    )

    refute item.valid?
    assert item.errors[:unit_price].any?
  end

  test "discount and tax rates must be between zero and one hundred" do
    item = InvoiceItem.new(
      invoice: @invoice,
      description: "Tonte",
      unit: "unit",
      discount_percentage: 101
    )

    refute item.valid?
    assert item.errors[:discount_percentage].any?

    item.discount_percentage = 0
    item.tax_rate = 101

    refute item.valid?
    assert item.errors[:tax_rate].any?
  end

  test "position is unique within invoice" do
    InvoiceItem.create!(
      invoice: @invoice,
      description: "First",
      unit: "unit",
      position: 1
    )

    duplicate = InvoiceItem.new(
      invoice: @invoice,
      description: "Duplicate",
      unit: "unit",
      position: 1
    )

    refute duplicate.valid?
    assert duplicate.errors[:position].any?
  end
end
