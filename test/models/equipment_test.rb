require "test_helper"

class EquipmentTest < ActiveSupport::TestCase
  setup do
    @organization = Organization.create!(name: "GreenPilot Equipment Test", slug: "greenpilot-equipment-test")
  end

  test "belongs to organization" do
    assert_equal :belongs_to, Equipment.reflect_on_association(:organization).macro
  end

  test "requires name and equipment type" do
    equipment = Equipment.new(organization: @organization)

    refute equipment.valid?
    assert equipment.errors[:name].any?
    assert equipment.errors[:equipment_type].any?
  end

  test "defaults to available status" do
    equipment = Equipment.new(
      organization: @organization,
      name: "Mower",
      equipment_type: "mower"
    )

    assert_equal "available", equipment.status
  end

  test "supports all defined statuses" do
    expected = %w[available in_use maintenance out_of_service retired].sort

    assert_equal expected, Equipment.statuses.keys.sort
  end

  test "purchase price cannot be negative" do
    equipment = Equipment.new(
      organization: @organization,
      name: "Mower",
      equipment_type: "mower",
      purchase_price: -1
    )

    refute equipment.valid?
    assert equipment.errors[:purchase_price].any?
  end

  test "maintenance interval must be positive" do
    equipment = Equipment.new(
      organization: @organization,
      name: "Mower",
      equipment_type: "mower",
      maintenance_interval_days: 0
    )

    refute equipment.valid?
    assert equipment.errors[:maintenance_interval_days].any?
  end

  test "serial number is unique within organization" do
    Equipment.create!(
      organization: @organization,
      name: "Mower One",
      equipment_type: "mower",
      serial_number: "SER-001"
    )

    duplicate = Equipment.new(
      organization: @organization,
      name: "Mower Two",
      equipment_type: "mower",
      serial_number: "SER-001"
    )

    refute duplicate.valid?
    assert duplicate.errors[:serial_number].any?
  end
end
