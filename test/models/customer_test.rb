require "test_helper"

class CustomerTest < ActiveSupport::TestCase
  setup do
    @organization = Organization.create!(name: "GreenPilot Customer Test", slug: "greenpilot-customer-test")
    @customer = Customer.new(organization: @organization)
  end

  test "belongs to organization" do
    assert_equal :belongs_to, Customer.reflect_on_association(:organization).macro
  end

  test "has sites" do
    assert_equal :has_many, Customer.reflect_on_association(:sites).macro
  end

  test "has quotes" do
    assert_equal :has_many, Customer.reflect_on_association(:quotes).macro
  end

  test "has jobs" do
    assert_equal :has_many, Customer.reflect_on_association(:jobs).macro
  end

  test "has invoices" do
    assert_equal :has_many, Customer.reflect_on_association(:invoices).macro
  end

  test "defaults to individual customer type" do
    assert_equal "individual", @customer.customer_type
  end

  test "supports individual and company customer types" do
    assert_equal %w[company individual], Customer.customer_types.keys.sort
  end
end
