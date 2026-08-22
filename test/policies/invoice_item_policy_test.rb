require "test_helper"

class InvoiceItemPolicyTest < ActiveSupport::TestCase
  test "authenticated user can list invoice items" do
    user = users(:member_a)

    assert InvoiceItemPolicy.new(user, InvoiceItem).index?
  end

  test "user can view invoice item from same organization" do
    user = users(:member_a)
    invoice_item = invoice_items(:invoice_item_a)

    assert InvoiceItemPolicy.new(user, invoice_item).show?
  end

  test "user cannot view invoice item from another organization" do
    user = users(:member_a)
    invoice_item = invoice_items(:invoice_item_b)

    assert_not InvoiceItemPolicy.new(user, invoice_item).show?
  end

  test "manager can create invoice item" do
    user = users(:manager_a)

    invoice_item = InvoiceItem.new(
      invoice: invoices(:invoice_a),
      service_item: service_items(:item_a),
      description: "Nouvelle prestation",
      quantity: 10,
      unit: "m2",
      unit_price: 15.00
    )

    assert InvoiceItemPolicy.new(user, invoice_item).create?
  end

  test "member cannot create invoice item" do
    user = users(:member_a)

    invoice_item = InvoiceItem.new(
      invoice: invoices(:invoice_a),
      service_item: service_items(:item_a),
      description: "Nouvelle prestation",
      quantity: 10,
      unit: "m2",
      unit_price: 15.00
    )

    assert_not InvoiceItemPolicy.new(user, invoice_item).create?
  end

  test "accountant cannot create invoice item" do
    user = users(:accountant_a)

    invoice_item = InvoiceItem.new(
      invoice: invoices(:invoice_a),
      service_item: service_items(:item_a),
      description: "Nouvelle prestation",
      quantity: 10,
      unit: "m2",
      unit_price: 15.00
    )

    assert_not InvoiceItemPolicy.new(user, invoice_item).create?
  end

  test "manager can update invoice item" do
    user = users(:manager_a)
    invoice_item = invoice_items(:invoice_item_a)

    assert InvoiceItemPolicy.new(user, invoice_item).update?
  end

  test "member cannot update invoice item" do
    user = users(:member_a)
    invoice_item = invoice_items(:invoice_item_a)

    assert_not InvoiceItemPolicy.new(user, invoice_item).update?
  end

  test "accountant cannot update invoice item" do
    user = users(:accountant_a)
    invoice_item = invoice_items(:invoice_item_a)

    assert_not InvoiceItemPolicy.new(user, invoice_item).update?
  end

  test "field worker cannot update invoice item" do
    user = users(:field_worker_a)
    invoice_item = invoice_items(:invoice_item_a)

    assert_not InvoiceItemPolicy.new(user, invoice_item).update?
  end

  test "manager cannot update invoice item from another organization" do
    user = users(:manager_a)
    invoice_item = invoice_items(:invoice_item_b)

    assert_not InvoiceItemPolicy.new(user, invoice_item).update?
  end

  test "accountant cannot update invoice item from another organization" do
    user = users(:accountant_a)
    invoice_item = invoice_items(:invoice_item_b)

    assert_not InvoiceItemPolicy.new(user, invoice_item).update?
  end

  test "owner can destroy invoice item" do
    user = users(:owner_a)
    invoice_item = invoice_items(:invoice_item_a)

    assert InvoiceItemPolicy.new(user, invoice_item).destroy?
  end

  test "admin can destroy invoice item" do
    user = users(:admin_a)
    invoice_item = invoice_items(:invoice_item_a)

    assert InvoiceItemPolicy.new(user, invoice_item).destroy?
  end

  test "manager cannot destroy invoice item" do
    user = users(:manager_a)
    invoice_item = invoice_items(:invoice_item_a)

    assert_not InvoiceItemPolicy.new(user, invoice_item).destroy?
  end

  test "accountant cannot destroy invoice item" do
    user = users(:accountant_a)
    invoice_item = invoice_items(:invoice_item_a)

    assert_not InvoiceItemPolicy.new(user, invoice_item).destroy?
  end

  test "field worker cannot destroy invoice item" do
    user = users(:field_worker_a)
    invoice_item = invoice_items(:invoice_item_a)

    assert_not InvoiceItemPolicy.new(user, invoice_item).destroy?
  end

  test "owner cannot destroy invoice item from another organization" do
    user = users(:owner_a)
    invoice_item = invoice_items(:invoice_item_b)

    assert_not InvoiceItemPolicy.new(user, invoice_item).destroy?
  end

  test "manager cannot create invoice item for foreign invoice" do
    user = users(:manager_a)

    invoice_item = InvoiceItem.new(
      invoice: invoices(:invoice_b),
      service_item: service_items(:item_a),
      description: "Cross organization",
      quantity: 10,
      unit: "m2",
      unit_price: 15.00
    )

    assert_not InvoiceItemPolicy.new(user, invoice_item).create?
  end

  test "manager cannot create invoice item with foreign service item" do
    user = users(:manager_a)

    invoice_item = InvoiceItem.new(
      invoice: invoices(:invoice_a),
      service_item: service_items(:item_b),
      description: "Cross organization",
      quantity: 10,
      unit: "m2",
      unit_price: 15.00
    )

    assert_not InvoiceItemPolicy.new(user, invoice_item).create?
  end

  test "manager cannot create invoice item without a service item" do
    user = users(:manager_a)

    invoice_item = InvoiceItem.new(
      invoice: invoices(:invoice_a),
      description: "Prestation libre",
      quantity: 10,
      unit: "m2",
      unit_price: 15.00
    )

    assert InvoiceItemPolicy.new(user, invoice_item).create?
  end

  test "scope returns only invoice items from user's organization" do
    user = users(:member_a)

    result = InvoiceItemPolicy::Scope
      .new(user, InvoiceItem.all)
      .resolve

    assert result.all? do |invoice_item|
      invoice_item.invoice.organization_id == user.organization_id &&
        (
          invoice_item.service_item.nil? ||
          invoice_item.service_item.organization_id == user.organization_id
        )
    end
  end
end