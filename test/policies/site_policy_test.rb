require "test_helper"

class SitePolicyTest < ActiveSupport::TestCase
  test "authenticated user can list sites" do
    user = users(:member_a)

    assert SitePolicy.new(user, Site).index?
  end

  test "user can view site from same organization" do
    user = users(:member_a)
    site = sites(:site_a)

    assert SitePolicy.new(user, site).show?
  end

  test "user cannot view site from another organization" do
    user = users(:member_a)
    site = sites(:site_b)

    assert_not SitePolicy.new(user, site).show?
  end

  test "owner can create site" do
    user = users(:owner_a)

    site = Site.new(
      organization: user.organization,
      customer: customers(:customer_a),
      name: "Nouveau site"
    )

    assert SitePolicy.new(user, site).create?
  end

  test "admin can create site" do
    user = users(:admin_a)

    site = Site.new(
      organization: user.organization,
      customer: customers(:customer_a),
      name: "Nouveau site"
    )

    assert SitePolicy.new(user, site).create?
  end

  test "manager can create site" do
    user = users(:manager_a)

    site = Site.new(
      organization: user.organization,
      customer: customers(:customer_a),
      name: "Nouveau site"
    )

    assert SitePolicy.new(user, site).create?
  end

  test "member cannot create site" do
    user = users(:member_a)

    site = Site.new(
      organization: user.organization,
      customer: customers(:customer_a),
      name: "Nouveau site"
    )

    assert_not SitePolicy.new(user, site).create?
  end

  test "accountant cannot create site" do
    user = users(:accountant_a)

    site = Site.new(
      organization: user.organization,
      customer: customers(:customer_a),
      name: "Nouveau site"
    )

    assert_not SitePolicy.new(user, site).create?
  end

  test "manager can update site from same organization" do
    user = users(:manager_a)
    site = sites(:site_a)

    assert SitePolicy.new(user, site).update?
  end

  test "member cannot update site" do
    user = users(:member_a)
    site = sites(:site_a)

    assert_not SitePolicy.new(user, site).update?
  end

  test "manager cannot update site from another organization" do
    user = users(:manager_a)
    site = sites(:site_b)

    assert_not SitePolicy.new(user, site).update?
  end

  test "owner can destroy site" do
    user = users(:owner_a)
    site = sites(:site_a)

    assert SitePolicy.new(user, site).destroy?
  end

  test "admin can destroy site" do
    user = users(:admin_a)
    site = sites(:site_a)

    assert SitePolicy.new(user, site).destroy?
  end

  test "manager cannot destroy site" do
    user = users(:manager_a)
    site = sites(:site_a)

    assert_not SitePolicy.new(user, site).destroy?
  end

  test "owner cannot destroy site from another organization" do
    user = users(:owner_a)
    site = sites(:site_b)

    assert_not SitePolicy.new(user, site).destroy?
  end

  test "cannot create site for customer from another organization" do
  user = users(:manager_a)

  site = Site.new(
    organization: organizations(:organization_a),
    customer: customers(:customer_b),
    name: "Cross organization site"
  )

  assert_not SitePolicy.new(user, site).create?
  end

  test "scope returns only sites from user's organization" do
    user = users(:member_a)

    result = SitePolicy::Scope
      .new(user, Site.all)
      .resolve

    assert result.all? do |site|
      site.organization_id == user.organization_id
    end
  end
end