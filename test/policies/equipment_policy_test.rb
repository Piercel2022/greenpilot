require "test_helper"

class EquipmentPolicyTest < ActiveSupport::TestCase
  test "authenticated user can list equipment" do
    user = users(:member_a)

    assert EquipmentPolicy.new(user, Equipment).index?
  end

  test "user can view equipment from same organization" do
    user = users(:member_a)
    equipment = equipment(:equipment_a)

    assert EquipmentPolicy.new(user, equipment).show?
  end

  test "user cannot view equipment from another organization" do
    user = users(:member_a)
    equipment = equipment(:equipment_b)

    assert_not EquipmentPolicy.new(user, equipment).show?
  end

  test "owner can create equipment" do
    user = users(:owner_a)

    equipment = Equipment.new(
      organization: user.organization,
      name: "Nouvel équipement Owner",
      equipment_type: "mower",
      status: "available"
    )

    assert EquipmentPolicy.new(user, equipment).create?
  end

  test "admin can create equipment" do
    user = users(:admin_a)

    equipment = Equipment.new(
      organization: user.organization,
      name: "Nouvel équipement Admin",
      equipment_type: "mower",
      status: "available"
    )

    assert EquipmentPolicy.new(user, equipment).create?
  end

  test "manager can create equipment" do
    user = users(:manager_a)

    equipment = Equipment.new(
      organization: user.organization,
      name: "Nouvel équipement Manager",
      equipment_type: "mower",
      status: "available"
    )

    assert EquipmentPolicy.new(user, equipment).create?
  end

  test "member cannot create equipment" do
    user = users(:member_a)

    equipment = Equipment.new(
      organization: user.organization,
      name: "Nouvel équipement Member",
      equipment_type: "mower",
      status: "available"
    )

    assert_not EquipmentPolicy.new(user, equipment).create?
  end

  test "accountant cannot create equipment" do
    user = users(:accountant_a)

    equipment = Equipment.new(
      organization: user.organization,
      name: "Nouvel équipement Accountant",
      equipment_type: "mower",
      status: "available"
    )

    assert_not EquipmentPolicy.new(user, equipment).create?
  end

  test "field worker cannot create equipment" do
    user = users(:field_worker_a)

    equipment = Equipment.new(
      organization: user.organization,
      name: "Nouvel équipement Field",
      equipment_type: "mower",
      status: "available"
    )

    assert_not EquipmentPolicy.new(user, equipment).create?
  end

  test "manager can update equipment from same organization" do
    user = users(:manager_a)
    equipment = equipment(:equipment_a)

    assert EquipmentPolicy.new(user, equipment).update?
  end

  test "member cannot update equipment" do
    user = users(:member_a)
    equipment = equipment(:equipment_a)

    assert_not EquipmentPolicy.new(user, equipment).update?
  end

  test "manager cannot update equipment from another organization" do
    user = users(:manager_a)
    equipment = equipment(:equipment_b)

    assert_not EquipmentPolicy.new(user, equipment).update?
  end

  test "owner can destroy equipment" do
    user = users(:owner_a)
    equipment = equipment(:equipment_a)

    assert EquipmentPolicy.new(user, equipment).destroy?
  end

  test "admin can destroy equipment" do
    user = users(:admin_a)
    equipment = equipment(:equipment_a)

    assert EquipmentPolicy.new(user, equipment).destroy?
  end

  test "manager cannot destroy equipment" do
    user = users(:manager_a)
    equipment = equipment(:equipment_a)

    assert_not EquipmentPolicy.new(user, equipment).destroy?
  end

  test "owner cannot destroy equipment from another organization" do
    user = users(:owner_a)
    equipment = equipment(:equipment_b)

    assert_not EquipmentPolicy.new(user, equipment).destroy?
  end

  test "scope returns only equipment from user's organization" do
    user = users(:member_a)

    result = EquipmentPolicy::Scope
      .new(user, Equipment.all)
      .resolve

    assert result.all? do |equipment|
      equipment.organization_id == user.organization_id
    end
  end
end