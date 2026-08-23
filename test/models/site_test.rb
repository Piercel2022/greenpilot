require "test_helper"

class SiteTest < ActiveSupport::TestCase
  setup do
    @organization = Organization.create!(name: "GreenPilot Site Test", slug: "greenpilot-site-test")
    @other_organization = Organization.create!(name: "Other Organization", slug: "other-site-test")

    @customer = Customer.create!(
      organization: @organization,
      first_name: "John",
      last_name: "Doe"
    )

    @other_customer = Customer.create!(
      organization: @other_organization,
      first_name: "Jane",
      last_name: "Doe"
    )
  end

  test "belongs to organization and customer" do
    assert_equal :belongs_to, Site.reflect_on_association(:organization).macro
    assert_equal :belongs_to, Site.reflect_on_association(:customer).macro
  end

  test "has quotes jobs and invoices" do
    assert_equal :has_many, Site.reflect_on_association(:quotes).macro
    assert_equal :has_many, Site.reflect_on_association(:jobs).macro
    assert_equal :has_many, Site.reflect_on_association(:invoices).macro
  end

  test "requires a name" do
    site = Site.new(
      organization: @organization,
      customer: @customer
    )

    refute site.valid?
    assert site.errors[:name].any?
  end

  test "is valid when customer belongs to same organization" do
    site = Site.new(
      organization: @organization,
      customer: @customer,
      name: "Main Garden"
    )

    assert site.valid?
  end

  test "rejects customer from another organization" do
    site = Site.new(
      organization: @organization,
      customer: @other_customer,
      name: "Invalid Site"
    )

    refute site.valid?
    assert_includes site.errors[:customer], "must belong to the same organization"
  end
end
