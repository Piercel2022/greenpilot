require "test_helper"

class QuotePolicyTest < ActiveSupport::TestCase
  test "authenticated user can list quotes" do
    user = users(:member_a)

    assert QuotePolicy.new(user, Quote).index?
  end

  test "user can view quote from same organization" do
    user = users(:member_a)
    quote = quotes(:quote_a)

    assert QuotePolicy.new(user, quote).show?
  end

  test "user cannot view quote from another organization" do
    user = users(:member_a)
    quote = quotes(:quote_b)

    assert_not QuotePolicy.new(user, quote).show?
  end

  test "manager can create quote" do
    user = users(:manager_a)

    quote = Quote.new(
      organization: user.organization,
      customer: customers(:customer_a),
      site: sites(:site_a),
      number: "DEV-NEW-001",
      title: "Nouvelle proposition",
      issue_date: Date.current
    )

    assert QuotePolicy.new(user, quote).create?
  end

  test "member cannot create quote" do
    user = users(:member_a)

    quote = Quote.new(
      organization: user.organization,
      customer: customers(:customer_a),
      site: sites(:site_a),
      number: "DEV-NEW-002",
      title: "Nouvelle proposition",
      issue_date: Date.current
    )

    assert_not QuotePolicy.new(user, quote).create?
  end

  test "accountant cannot create quote" do
    user = users(:accountant_a)

    quote = Quote.new(
      organization: user.organization,
      customer: customers(:customer_a),
      site: sites(:site_a),
      number: "DEV-NEW-003",
      title: "Nouvelle proposition",
      issue_date: Date.current
    )

    assert_not QuotePolicy.new(user, quote).create?
  end

  test "manager can update quote" do
    user = users(:manager_a)
    quote = quotes(:quote_a)

    assert QuotePolicy.new(user, quote).update?
  end

  test "member cannot update quote" do
    user = users(:member_a)
    quote = quotes(:quote_a)

    assert_not QuotePolicy.new(user, quote).update?
  end

  test "accountant cannot update quote" do
    user = users(:accountant_a)
    quote = quotes(:quote_a)

    assert_not QuotePolicy.new(user, quote).update?
  end

  test "manager cannot update quote from another organization" do
    user = users(:manager_a)
    quote = quotes(:quote_b)

    assert_not QuotePolicy.new(user, quote).update?
  end

  test "owner can destroy quote" do
    user = users(:owner_a)
    quote = quotes(:quote_a)

    assert QuotePolicy.new(user, quote).destroy?
  end

  test "admin can destroy quote" do
    user = users(:admin_a)
    quote = quotes(:quote_a)

    assert QuotePolicy.new(user, quote).destroy?
  end

  test "manager cannot destroy quote" do
    user = users(:manager_a)
    quote = quotes(:quote_a)

    assert_not QuotePolicy.new(user, quote).destroy?
  end

  test "accountant cannot destroy quote" do
    user = users(:accountant_a)
    quote = quotes(:quote_a)

    assert_not QuotePolicy.new(user, quote).destroy?
  end

  test "field worker cannot destroy quote" do
    user = users(:field_worker_a)
    quote = quotes(:quote_a)

    assert_not QuotePolicy.new(user, quote).destroy?
  end

  test "owner cannot destroy quote from another organization" do
    user = users(:owner_a)
    quote = quotes(:quote_b)

    assert_not QuotePolicy.new(user, quote).destroy?
  end


  test "manager cannot update quote with foreign customer" do
    user = users(:manager_a)
    quote = quotes(:quote_a)

    quote.customer = customers(:customer_b)

    assert_not QuotePolicy.new(user, quote).update?
  end

  test "manager cannot update quote with foreign site" do
    user = users(:manager_a)
    quote = quotes(:quote_a)

    quote.site = sites(:site_b)

    assert_not QuotePolicy.new(user, quote).update?
  end

  test "scope returns only quotes from user's organization" do
    user = users(:member_a)

    result = QuotePolicy::Scope
      .new(user, Quote.all)
      .resolve

    assert result.all? do |quote|
      quote.organization_id == user.organization_id &&
        quote.customer.organization_id == user.organization_id &&
        quote.site.organization_id == user.organization_id
    end
  end
end