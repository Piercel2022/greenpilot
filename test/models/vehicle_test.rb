require "test_helper"

class VehicleTest < ActiveSupport::TestCase
  setup do
    @organization = Organization.create!(name: "GreenPilot Vehicle Test", slug: "greenpilot-vehicle-test")
  end

  test "belongs to organization" do
    assert_equal :belongs_to, Vehicle.reflect_on_association(:organization).macro
  end

  test "has jobs" do
    assert_equal :has_many, Vehicle.reflect_on_association(:jobs).macro
  end

  test "requires name and registration number" do
    vehicle = Vehicle.new(organization: @organization)

    refute vehicle.valid?
    assert vehicle.errors[:name].any?
    assert vehicle.errors[:registration_number].any?
  end

  test "registration number is unique within organization" do
    Vehicle.create!(
      organization: @organization,
      name: "Van One",
      registration_number: "AB-123-CD"
    )

    duplicate = Vehicle.new(
      organization: @organization,
      name: "Van Two",
      registration_number: "AB-123-CD"
    )

    refute duplicate.valid?
    assert duplicate.errors[:registration_number].any?
  end

  test "active and inactive scopes work" do
    active = Vehicle.create!(
      organization: @organization,
      name: "Active Van",
      registration_number: "AA-111-AA",
      active: true
    )

    inactive = Vehicle.create!(
      organization: @organization,
      name: "Inactive Van",
      registration_number: "BB-222-BB",
      active: false
    )

    assert_includes Vehicle.active, active
    assert_includes Vehicle.inactive, inactive
  end
end
