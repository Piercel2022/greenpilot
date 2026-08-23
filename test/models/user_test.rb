require "test_helper"

class UserTest < ActiveSupport::TestCase
  setup do
    @organization = Organization.create!(name: "GreenPilot Test", slug: "greenpilot-user-test")
    @user = User.new(
      organization: @organization,
      email: "user@example.com",
      first_name: "John",
      last_name: "Doe"
    )
  end

  test "belongs to organization" do
    assert_equal :belongs_to, User.reflect_on_association(:organization).macro
  end

  test "has team memberships" do
    assert_equal :has_many, User.reflect_on_association(:team_memberships).macro
  end

  test "has jobs through job assignments" do
    association = User.reflect_on_association(:jobs)

    assert_equal :has_many, association.macro
    assert_equal :job_assignments, association.options[:through]
  end

  test "has job time entries" do
    assert_equal :has_many, User.reflect_on_association(:job_time_entries).macro
  end

  test "defaults to member role" do
    assert_equal "member", @user.role
  end

  test "supports all defined roles" do
    assert_equal %w[member field_worker accountant manager admin owner].sort, User.roles.keys.sort
  end

    test "authenticates with a valid password" do
    user = User.new(
      organization: @organization,
      email: "auth@example.com",
      first_name: "Auth",
      last_name: "User",
      password: "password123",
      password_confirmation: "password123"
    )

    user.save!

    assert user.authenticate("password123")
    refute user.authenticate("wrong-password")
  end

  test "requires matching password confirmation" do
    user = User.new(
      organization: @organization,
      email: "mismatch@example.com",
      first_name: "Mismatch",
      last_name: "User",
      password: "password123",
      password_confirmation: "wrong-password"
    )

    refute user.valid?
    assert user.errors[:password_confirmation].any?
  end
end
