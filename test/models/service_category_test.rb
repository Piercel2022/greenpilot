require "test_helper"

class ServiceCategoryTest < ActiveSupport::TestCase
  setup do
    @organization = Organization.create!(name: "GreenPilot Category Test", slug: "greenpilot-category-test")
  end

  test "belongs to organization" do
    assert_equal :belongs_to, ServiceCategory.reflect_on_association(:organization).macro
  end

  test "has service items" do
    assert_equal :has_many, ServiceCategory.reflect_on_association(:service_items).macro
  end

  test "requires code and name" do
    category = ServiceCategory.new(organization: @organization)

    refute category.valid?
    assert category.errors[:code].any?
    assert category.errors[:name].any?
  end

  test "code is unique within organization" do
    ServiceCategory.create!(
      organization: @organization,
      code: "ENT",
      name: "Entretien"
    )

    duplicate = ServiceCategory.new(
      organization: @organization,
      code: "ENT",
      name: "Another category"
    )

    refute duplicate.valid?
    assert duplicate.errors[:code].any?
  end

  test "same code is allowed in another organization" do
    other_organization = Organization.create!(
      name: "Other Category Organization",
      slug: "other-category-organization"
    )

    ServiceCategory.create!(
      organization: @organization,
      code: "ENT",
      name: "Entretien"
    )

    category = ServiceCategory.new(
      organization: other_organization,
      code: "ENT",
      name: "Entretien"
    )

    assert category.valid?
  end

  test "ordered scope sorts by position then name" do
    ServiceCategory.create!(organization: @organization, code: "B", name: "B", position: 2)
    ServiceCategory.create!(organization: @organization, code: "A", name: "A", position: 1)

    assert_equal %w[A B], ServiceCategory.where(organization: @organization).ordered.pluck(:code)
  end
end
