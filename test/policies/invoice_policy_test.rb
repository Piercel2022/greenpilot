require "test_helper"

class InvoicePolicyTest < ActiveSupport::TestCase
  test "authenticated user can list invoices" do
    user = users(:member_a)

    assert InvoicePolicy.new(user, Invoice).index?
  end

  test "user can view invoice from same organization" do
    user = users(:member_a)
    invoice = invoices(:invoice_a)

    assert InvoicePolicy.new(user, invoice).show?
  end

  test "user cannot view invoice from another organization" do
    user = users(:member_a)
    invoice = invoices(:invoice_b)

    assert_not InvoicePolicy.new(user, invoice).show?
  end

  test "manager can create invoice" do
    user = users(:manager_a)

    invoice = Invoice.new(
      organization: user.organization,
      customer: customers(:customer_a),
      site: sites(:site_a),
      job: jobs(:job_a),
      quote: quotes(:quote_a),
      number: "INV-TEST-001",
      issue_date: Date.current
    )

    assert InvoicePolicy.new(user, invoice).create?
  end

  test "member cannot create invoice" do
    user = users(:member_a)

    invoice = Invoice.new(
      organization: user.organization,
      customer: customers(:customer_a),
      number: "INV-TEST-002",
      issue_date: Date.current
    )

    assert_not InvoicePolicy.new(user, invoice).create?
  end

  test "accountant cannot create invoice" do
    user = users(:accountant_a)

    invoice = Invoice.new(
      organization: user.organization,
      customer: customers(:customer_a),
      number: "INV-TEST-003",
      issue_date: Date.current
    )

    assert_not InvoicePolicy.new(user, invoice).create?
  end

  test "accountant can update invoice" do
    user = users(:accountant_a)
    invoice = invoices(:invoice_a)

    assert InvoicePolicy.new(user, invoice).update?
  end

  test "manager can update invoice" do
    user = users(:manager_a)
    invoice = invoices(:invoice_a)

    assert InvoicePolicy.new(user, invoice).update?
  end

  test "member cannot update invoice" do
    user = users(:member_a)
    invoice = invoices(:invoice_a)

    assert_not InvoicePolicy.new(user, invoice).update?
  end

  test "field worker cannot update invoice" do
    user = users(:field_worker_a)
    invoice = invoices(:invoice_a)

    assert_not InvoicePolicy.new(user, invoice).update?
  end

  test "manager cannot update invoice from another organization" do
    user = users(:manager_a)
    invoice = invoices(:invoice_b)

    assert_not InvoicePolicy.new(user, invoice).update?
  end

  test "accountant cannot update invoice from another organization" do
    user = users(:accountant_a)
    invoice = invoices(:invoice_b)

    assert_not InvoicePolicy.new(user, invoice).update?
  end

  test "owner can destroy invoice" do
    user = users(:owner_a)
    invoice = invoices(:invoice_a)

    assert InvoicePolicy.new(user, invoice).destroy?
  end

  test "admin can destroy invoice" do
    user = users(:admin_a)
    invoice = invoices(:invoice_a)

    assert InvoicePolicy.new(user, invoice).destroy?
  end

  test "manager cannot destroy invoice" do
    user = users(:manager_a)
    invoice = invoices(:invoice_a)

    assert_not InvoicePolicy.new(user, invoice).destroy?
  end

  test "accountant cannot destroy invoice" do
    user = users(:accountant_a)
    invoice = invoices(:invoice_a)

    assert_not InvoicePolicy.new(user, invoice).destroy?
  end

  test "field worker cannot destroy invoice" do
    user = users(:field_worker_a)
    invoice = invoices(:invoice_a)

    assert_not InvoicePolicy.new(user, invoice).destroy?
  end

  test "owner cannot destroy invoice from another organization" do
    user = users(:owner_a)
    invoice = invoices(:invoice_b)

    assert_not InvoicePolicy.new(user, invoice).destroy?
  end

  test "manager cannot create invoice for foreign customer" do
    user = users(:manager_a)

    invoice = Invoice.new(
      organization: user.organization,
      customer: customers(:customer_b),
      number: "INV-TEST-004",
      issue_date: Date.current
    )

    assert_not InvoicePolicy.new(user, invoice).create?
  end

  test "manager cannot create invoice with foreign job" do
    user = users(:manager_a)

    invoice = Invoice.new(
      organization: user.organization,
      customer: customers(:customer_a),
      job: jobs(:job_b),
      number: "INV-TEST-005",
      issue_date: Date.current
    )

    assert_not InvoicePolicy.new(user, invoice).create?
  end

  test "manager cannot create invoice with foreign quote" do
    user = users(:manager_a)

    invoice = Invoice.new(
      organization: user.organization,
      customer: customers(:customer_a),
      quote: quotes(:quote_b),
      number: "INV-TEST-006",
      issue_date: Date.current
    )

    assert_not InvoicePolicy.new(user, invoice).create?
  end

  test "manager cannot create invoice with foreign site" do
    user = users(:manager_a)

    invoice = Invoice.new(
      organization: user.organization,
      customer: customers(:customer_a),
      site: sites(:site_b),
      number: "INV-TEST-007",
      issue_date: Date.current
    )

    assert_not InvoicePolicy.new(user, invoice).create?
  end

  test "scope returns only invoices from user's organization" do
    user = users(:member_a)

    result = InvoicePolicy::Scope
      .new(user, Invoice.all)
      .resolve

    assert result.all? do |invoice|
      invoice.organization_id == user.organization_id &&
        invoice.customer.organization_id == user.organization_id &&
        (!invoice.job || invoice.job.organization_id == user.organization_id) &&
        (!invoice.quote || invoice.quote.organization_id == user.organization_id) &&
        (!invoice.site || invoice.site.organization_id == user.organization_id)
    end
  end
end