require "test_helper"

class QuoteItemPolicyTest < ActiveSupport::TestCase
  test "authenticated user can list quote items" do
    user = users(:member_a)

    assert QuoteItemPolicy.new(user, QuoteItem).index?
  end

  test "user can view quote item from same organization" do
    user = users(:member_a)
    item = quote_items(:quote_item_a)

    assert QuoteItemPolicy.new(user, item).show?
  end

  test "user cannot view quote item from another organization" do
    user = users(:member_a)
    item = quote_items(:quote_item_b)

    assert_not QuoteItemPolicy.new(user, item).show?
  end

  test "manager can create quote item for same organization" do
    user = users(:manager_a)

    item = QuoteItem.new(
      quote: quotes(:quote_a),
      service_item: service_items(:item_a),
      quantity: 1,
      unit_price: 100
    )

    assert QuoteItemPolicy.new(user, item).create?
  end

  test "member cannot create quote item" do
    user = users(:member_a)

    item = QuoteItem.new(
      quote: quotes(:quote_a),
      service_item: service_items(:item_a),
      quantity: 1,
      unit_price: 100
    )

    assert_not QuoteItemPolicy.new(user, item).create?
  end

  test "accountant cannot create quote item" do
    user = users(:accountant_a)

    item = QuoteItem.new(
      quote: quotes(:quote_a),
      service_item: service_items(:item_a),
      quantity: 1,
      unit_price: 100
    )

    assert_not QuoteItemPolicy.new(user, item).create?
  end

  test "field worker cannot create quote item" do
    user = users(:field_worker_a)

    item = QuoteItem.new(
      quote: quotes(:quote_a),
      service_item: service_items(:item_a),
      quantity: 1,
      unit_price: 100
    )

    assert_not QuoteItemPolicy.new(user, item).create?
  end

  test "manager can update quote item from same organization" do
    user = users(:manager_a)
    item = quote_items(:quote_item_a)

    assert QuoteItemPolicy.new(user, item).update?
  end

  test "member cannot update quote item" do
    user = users(:member_a)
    item = quote_items(:quote_item_a)

    assert_not QuoteItemPolicy.new(user, item).update?
  end

  test "manager cannot update quote item from another organization" do
    user = users(:manager_a)
    item = quote_items(:quote_item_b)

    assert_not QuoteItemPolicy.new(user, item).update?
  end

  test "owner can destroy quote item" do
    user = users(:owner_a)
    item = quote_items(:quote_item_a)

    assert QuoteItemPolicy.new(user, item).destroy?
  end

  test "admin can destroy quote item" do
    user = users(:admin_a)
    item = quote_items(:quote_item_a)

    assert QuoteItemPolicy.new(user, item).destroy?
  end

  test "manager cannot destroy quote item" do
    user = users(:manager_a)
    item = quote_items(:quote_item_a)

    assert_not QuoteItemPolicy.new(user, item).destroy?
  end

  test "owner cannot destroy quote item from another organization" do
    user = users(:owner_a)
    item = quote_items(:quote_item_b)

    assert_not QuoteItemPolicy.new(user, item).destroy?
  end

  test "manager cannot create quote item with foreign service item" do
    user = users(:manager_a)

    item = QuoteItem.new(
      quote: quotes(:quote_a),
      service_item: service_items(:item_b),
      quantity: 1,
      unit_price: 100
    )

    assert_not QuoteItemPolicy.new(user, item).create?
  end

  test "manager cannot create quote item with foreign quote" do
    user = users(:manager_a)

    item = QuoteItem.new(
      quote: quotes(:quote_b),
      service_item: service_items(:item_a),
      quantity: 1,
      unit_price: 100
    )

    assert_not QuoteItemPolicy.new(user, item).create?
  end

  test "manager cannot update quote item with foreign service item" do
    user = users(:manager_a)
    item = quote_items(:quote_item_a)

    item.service_item = service_items(:item_b)

    assert_not QuoteItemPolicy.new(user, item).update?
  end

  test "manager cannot update quote item with foreign quote" do
    user = users(:manager_a)
    item = quote_items(:quote_item_a)

    item.quote = quotes(:quote_b)

    assert_not QuoteItemPolicy.new(user, item).update?
  end

  test "owner cannot destroy quote item with foreign service item" do
    user = users(:owner_a)
    item = quote_items(:quote_item_a)

    item.service_item = service_items(:item_b)

    assert_not QuoteItemPolicy.new(user, item).destroy?
  end

  test "scope returns only quote items from user's organization" do
    user = users(:member_a)

    result = QuoteItemPolicy::Scope
      .new(user, QuoteItem.all)
      .resolve

    assert result.all? do |item|
      item.quote.organization_id == user.organization_id &&
        item.service_item.organization_id == user.organization_id
    end
  end

  test "scope excludes quote items from another organization" do
    user = users(:member_a)

    all_items = QuoteItem.all

    result = QuoteItemPolicy::Scope
      .new(user, all_items)
      .resolve

    assert_includes all_items, quote_items(:quote_item_b)
    assert_not_includes result, quote_items(:quote_item_b)
  end
end
