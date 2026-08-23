require "test_helper"

class ServiceItemTest < ActiveSupport::TestCase
  setup do
    @organization = Organization.create!(name: "GreenPilot Item Test", slug: "greenpilot-item-test")
    @category = ServiceCategory.create!(
      organization: @organization,
      code: "ENT",
      name: "Entretien"
    )
  end

  test "belongs to organization and service category" do
    assert_equal :belongs_to, ServiceItem.reflect_on_association(:organization).macro
    assert_equal :belongs_to, ServiceItem.reflect_on_association(:service_category).macro
  end

  test "has quote items and invoice items" do
    assert_equal :has_many, ServiceItem.reflect_on_association(:quote_items).macro
    assert_equal :has_many, ServiceItem.reflect_on_association(:invoice_items).macro
  end

  test "requires code and name" do
    item = ServiceItem.new(
      organization: @organization,
      service_category: @category
    )

    refute item.valid?
    assert item.errors[:code].any?
    assert item.errors[:name].any?
  end

  test "code is unique within organization" do
    ServiceItem.create!(
      organization: @organization,
      service_category: @category,
      code: "TONTE",
      name: "Tonte"
    )

    duplicate = ServiceItem.new(
      organization: @organization,
      service_category: @category,
      code: "TONTE",
      name: "Tonte duplicate"
    )

    refute duplicate.valid?
    assert duplicate.errors[:code].any?
  end

  test "ordered scope sorts by position then name" do
    ServiceItem.create!(
      organization: @organization,
      service_category: @category,
      code: "B",
      name: "B",
      position: 2
    )

    ServiceItem.create!(
      organization: @organization,
      service_category: @category,
      code: "A",
      name: "A",
      position: 1
    )

    assert_equal %w[A B], ServiceItem.where(organization: @organization).ordered.pluck(:code)
  end
end
