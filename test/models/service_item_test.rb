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

  test "same code is allowed in another organization" do
    other_organization = Organization.create!(
      name: "Other Item Organization",
      slug: "other-item-organization"
    )

    other_category = ServiceCategory.create!(
      organization: other_organization,
      code: "ENT",
      name: "Entretien"
    )

    ServiceItem.create!(
      organization: @organization,
      service_category: @category,
      code: "TONTE",
      name: "Tonte"
    )

    item = ServiceItem.new(
      organization: other_organization,
      service_category: other_category,
      code: "TONTE",
      name: "Tonte autre organisation"
    )

    assert item.valid?
  end

  test "service category must belong to the same organization" do
    other_organization = Organization.create!(
      name: "Other Item Organization",
      slug: "other-item-organization"
    )

    other_category = ServiceCategory.create!(
      organization: other_organization,
      code: "OTH",
      name: "Other"
    )

    item = ServiceItem.new(
      organization: @organization,
      service_category: other_category,
      code: "CROSS",
      name: "Cross organization item"
    )

    refute item.valid?

    assert_includes item.errors[:service_category],
                     "must belong to the same organization"
  end

  test "service category from same organization is allowed" do
    item = ServiceItem.new(
      organization: @organization,
      service_category: @category,
      code: "VALID",
      name: "Valid item"
    )

    assert item.valid?
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
