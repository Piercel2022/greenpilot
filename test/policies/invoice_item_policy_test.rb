
require "test_helper"

class InvoiceItemPolicyTest < ActiveSupport::TestCase
  # ---------------------------------------------------------------------------
  # INDEX
  # ---------------------------------------------------------------------------

  test "authenticated user can list invoice items" do
    user = users(:member_a)

    assert InvoiceItemPolicy.new(user, InvoiceItem).index?
  end

  test "unauthenticated user cannot list invoice items" do
    assert_not InvoiceItemPolicy.new(nil, InvoiceItem).index?
  end

  # ---------------------------------------------------------------------------
  # SHOW
  # ---------------------------------------------------------------------------

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

  test "unauthenticated user cannot view invoice item" do
    invoice_item = invoice_items(:invoice_item_a)

    assert_not InvoiceItemPolicy.new(nil, invoice_item).show?
  end

  test "user cannot view invoice item without invoice" do
    user = users(:member_a)

    invoice_item = InvoiceItem.new(
      service_item: service_items(:item_a),
      description: "Sans facture",
      quantity: 10,
      unit: "m2",
      unit_price: 15.00
    )

    assert_not InvoiceItemPolicy.new(user, invoice_item).show?
  end

  test "user cannot view invoice item with foreign service item" do
    user = users(:member_a)

    invoice_item = InvoiceItem.new(
      invoice: invoices(:invoice_a),
      service_item: service_items(:item_b),
      description: "Service étranger",
      quantity: 10,
      unit: "m2",
      unit_price: 15.00
    )

    assert_not InvoiceItemPolicy.new(user, invoice_item).show?
  end

  # ---------------------------------------------------------------------------
  # CREATE
  # ---------------------------------------------------------------------------

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

  test "owner can create invoice item" do
    user = users(:owner_a)

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

  test "admin can create invoice item" do
    user = users(:admin_a)

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

  test "field worker cannot create invoice item" do
    user = users(:field_worker_a)

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

  test "unauthenticated user cannot create invoice item" do
    invoice_item = InvoiceItem.new(
      invoice: invoices(:invoice_a),
      service_item: service_items(:item_a),
      description: "Nouvelle prestation",
      quantity: 10,
      unit: "m2",
      unit_price: 15.00
    )

    assert_not InvoiceItemPolicy.new(nil, invoice_item).create?
  end

  test "manager can create invoice item without a service item" do
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

  test "manager cannot create invoice item without an invoice" do
    user = users(:manager_a)

    invoice_item = InvoiceItem.new(
      service_item: service_items(:item_a),
      description: "Sans facture",
      quantity: 10,
      unit: "m2",
      unit_price: 15.00
    )

    assert_not InvoiceItemPolicy.new(user, invoice_item).create?
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

  # ---------------------------------------------------------------------------
  # UPDATE
  # ---------------------------------------------------------------------------

  test "manager can update invoice item" do
    user = users(:manager_a)
    invoice_item = invoice_items(:invoice_item_a)

    assert InvoiceItemPolicy.new(user, invoice_item).update?
  end

  test "owner can update invoice item" do
    user = users(:owner_a)
    invoice_item = invoice_items(:invoice_item_a)

    assert InvoiceItemPolicy.new(user, invoice_item).update?
  end

  test "admin can update invoice item" do
    user = users(:admin_a)
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

  test "unauthenticated user cannot update invoice item" do
    invoice_item = invoice_items(:invoice_item_a)

    assert_not InvoiceItemPolicy.new(nil, invoice_item).update?
  end

  test "manager cannot update invoice item from another organization" do
    user = users(:manager_a)
    invoice_item = invoice_items(:invoice_item_b)

    assert_not InvoiceItemPolicy.new(user, invoice_item).update?
  end

  test "owner cannot update invoice item from another organization" do
    user = users(:owner_a)
    invoice_item = invoice_items(:invoice_item_b)

    assert_not InvoiceItemPolicy.new(user, invoice_item).update?
  end

  test "admin cannot update invoice item from another organization" do
    user = users(:admin_a)
    invoice_item = invoice_items(:invoice_item_b)

    assert_not InvoiceItemPolicy.new(user, invoice_item).update?
  end

  test "manager cannot update invoice item with foreign invoice" do
    user = users(:manager_a)

    invoice_item = invoice_items(:invoice_item_a)
    invoice_item.invoice = invoices(:invoice_b)

    assert_not InvoiceItemPolicy.new(user, invoice_item).update?
  end

  test "manager cannot update invoice item with foreign service item" do
    user = users(:manager_a)

    invoice_item = invoice_items(:invoice_item_a)
    invoice_item.service_item = service_items(:item_b)

    assert_not InvoiceItemPolicy.new(user, invoice_item).update?
  end

  test "manager cannot update invoice item without an invoice" do
    user = users(:manager_a)

    invoice_item = invoice_items(:invoice_item_a)
    invoice_item.invoice = nil

    assert_not InvoiceItemPolicy.new(user, invoice_item).update?
  end

  test "manager can update invoice item without a service item" do
    user = users(:manager_a)

    invoice_item = invoice_items(:invoice_item_a)
    invoice_item.service_item = nil

    assert InvoiceItemPolicy.new(user, invoice_item).update?
  end

  # ---------------------------------------------------------------------------
  # DESTROY
  # ---------------------------------------------------------------------------

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

  test "member cannot destroy invoice item" do
    user = users(:member_a)
    invoice_item = invoice_items(:invoice_item_a)

    assert_not InvoiceItemPolicy.new(user, invoice_item).destroy?
  end

  test "unauthenticated user cannot destroy invoice item" do
    invoice_item = invoice_items(:invoice_item_a)

    assert_not InvoiceItemPolicy.new(nil, invoice_item).destroy?
  end

  test "owner cannot destroy invoice item from another organization" do
    user = users(:owner_a)
    invoice_item = invoice_items(:invoice_item_b)

    assert_not InvoiceItemPolicy.new(user, invoice_item).destroy?
  end

  test "admin cannot destroy invoice item from another organization" do
    user = users(:admin_a)
    invoice_item = invoice_items(:invoice_item_b)

    assert_not InvoiceItemPolicy.new(user, invoice_item).destroy?
  end

  test "owner cannot destroy invoice item with foreign service item" do
    user = users(:owner_a)

    invoice_item = invoice_items(:invoice_item_a)
    invoice_item.service_item = service_items(:item_b)

    assert_not InvoiceItemPolicy.new(user, invoice_item).destroy?
  end

  test "owner cannot destroy invoice item without an invoice" do
    user = users(:owner_a)

    invoice_item = invoice_items(:invoice_item_a)
    invoice_item.invoice = nil

    assert_not InvoiceItemPolicy.new(user, invoice_item).destroy?
  end

  # ---------------------------------------------------------------------------
  # SCOPE
  # ---------------------------------------------------------------------------

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


  test "scope excludes invoice item with foreign invoice" do
    user = users(:member_a)

    invoice_item = InvoiceItem.create!(
      invoice: invoices(:invoice_a),
      service_item: service_items(:item_a),
      description: "Foreign invoice scope test",
      position: 99,
      quantity: 1,
      unit: "unit",
      unit_price: 10.00,
      discount_percentage: 0.0,
      tax_rate: 20.0,
      subtotal: 10.00,
      tax_amount: 2.00,
      total_amount: 12.00
    )

    invoice_item.update_column(:invoice_id, invoices(:invoice_b).id)

    result = InvoiceItemPolicy::Scope
      .new(user, InvoiceItem.all)
      .resolve

    assert_not_includes result, invoice_item
  end

  test "scope excludes invoice item with foreign service item" do
    user = users(:member_a)

    invoice_item = invoice_items(:invoice_item_a)
    invoice_item.update_column(:service_item_id, service_items(:item_b).id)

    result = InvoiceItemPolicy::Scope
      .new(user, InvoiceItem.all)
      .resolve

    assert_not_includes result, invoice_item
  end

  test "scope includes invoice item without service item" do
    user = users(:member_a)

    invoice_item = invoice_items(:invoice_item_a)
    invoice_item.update_column(:service_item_id, nil)

    result = InvoiceItemPolicy::Scope
      .new(user, InvoiceItem.all)
      .resolve

    assert_includes result, invoice_item
  end

  test "scope excludes invoice items from another organization" do
    user = users(:member_a)

    result = InvoiceItemPolicy::Scope
      .new(user, InvoiceItem.all)
      .resolve

    assert_not_includes result, invoice_items(:invoice_item_b)
  end
end