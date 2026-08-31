require "test_helper"

class VehiclePolicyTest < ActiveSupport::TestCase
  test "authenticated user can list vehicles" do
    user = users(:member_a)

    assert VehiclePolicy.new(user, Vehicle).index?
  end

  test "user can view vehicle from same organization" do
    user = users(:member_a)
    vehicle = vehicles(:vehicle_a)

    assert VehiclePolicy.new(user, vehicle).show?
  end

  test "user cannot view vehicle from another organization" do
    user = users(:member_a)
    vehicle = vehicles(:vehicle_b)

    assert_not VehiclePolicy.new(user, vehicle).show?
  end

  test "owner can create vehicle" do
    user = users(:owner_a)

    vehicle = Vehicle.new(
      organization: user.organization,
      name: "Nouveau véhicule Owner",
      registration_number: "AA-111-AA"
    )

    assert VehiclePolicy.new(user, vehicle).create?
  end

  test "admin can create vehicle" do
    user = users(:admin_a)

    vehicle = Vehicle.new(
      organization: user.organization,
      name: "Nouveau véhicule Admin",
      registration_number: "BB-222-BB"
    )

    assert VehiclePolicy.new(user, vehicle).create?
  end

  test "manager can create vehicle" do
    user = users(:manager_a)

    vehicle = Vehicle.new(
      organization: user.organization,
      name: "Nouveau véhicule Manager",
      registration_number: "CC-333-CC"
    )

    assert VehiclePolicy.new(user, vehicle).create?
  end

  test "member cannot create vehicle" do
    user = users(:member_a)

    vehicle = Vehicle.new(
      organization: user.organization,
      name: "Nouveau véhicule Member",
      registration_number: "DD-444-DD"
    )

    assert_not VehiclePolicy.new(user, vehicle).create?
  end

  test "accountant cannot create vehicle" do
    user = users(:accountant_a)

    vehicle = Vehicle.new(
      organization: user.organization,
      name: "Nouveau véhicule Accountant",
      registration_number: "EE-555-EE"
    )

    assert_not VehiclePolicy.new(user, vehicle).create?
  end

  test "field worker cannot create vehicle" do
    user = users(:field_worker_a)

    vehicle = Vehicle.new(
      organization: user.organization,
      name: "Nouveau véhicule Field",
      registration_number: "FF-666-FF"
    )

    assert_not VehiclePolicy.new(user, vehicle).create?
  end

  test "manager can update vehicle from same organization" do
    user = users(:manager_a)
    vehicle = vehicles(:vehicle_a)

    assert VehiclePolicy.new(user, vehicle).update?
  end

  test "member cannot update vehicle" do
    user = users(:member_a)
    vehicle = vehicles(:vehicle_a)

    assert_not VehiclePolicy.new(user, vehicle).update?
  end

  test "manager cannot update vehicle from another organization" do
    user = users(:manager_a)
    vehicle = vehicles(:vehicle_b)

    assert_not VehiclePolicy.new(user, vehicle).update?
  end

  test "owner can destroy vehicle" do
    user = users(:owner_a)
    vehicle = vehicles(:vehicle_a)

    assert VehiclePolicy.new(user, vehicle).destroy?
  end

  test "admin can destroy vehicle" do
    user = users(:admin_a)
    vehicle = vehicles(:vehicle_a)

    assert VehiclePolicy.new(user, vehicle).destroy?
  end

  test "manager cannot destroy vehicle" do
    user = users(:manager_a)
    vehicle = vehicles(:vehicle_a)

    assert_not VehiclePolicy.new(user, vehicle).destroy?
  end

  test "owner cannot destroy vehicle from another organization" do
    user = users(:owner_a)
    vehicle = vehicles(:vehicle_b)

    assert_not VehiclePolicy.new(user, vehicle).destroy?
  end

  test "scope returns only vehicles from user's organization" do
    user = users(:member_a)

    result = VehiclePolicy::Scope
      .new(user, Vehicle.all)
      .resolve

    assert result.all? do |vehicle|
      vehicle.organization_id == user.organization_id
    end
  end

  test "manager cannot create vehicle for another organization" do
    user = users(:manager_a)

    vehicle = Vehicle.new(
      organization: organizations(:organization_b),
      name: "Foreign Organization Vehicle",
      registration_number: "FOREIGN-001"
    )

    assert_not VehiclePolicy.new(user, vehicle).create?
  end
end
