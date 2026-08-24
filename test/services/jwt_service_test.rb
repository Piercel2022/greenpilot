require "test_helper"

class JwtServiceTest < ActiveSupport::TestCase
  setup do
    @organization = Organization.create!(
      name: "JWT Test Organization",
      slug: "jwt-test-organization"
    )

    @user = User.create!(
      organization: @organization,
      email: "jwt@example.com",
      first_name: "JWT",
      last_name: "User",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  test "encodes a user into a JWT" do
    token = JwtService.encode(@user)

    assert token.present?
    assert_kind_of String, token
  end

  test "decodes a valid JWT" do
    token = JwtService.encode(@user)

    payload = JwtService.decode(token)

    assert_equal @user.id, payload["sub"]
    assert payload["iat"].present?
    assert payload["exp"].present?
  end

  test "rejects an invalid token" do
    assert_raises(JwtService::Error) do
      JwtService.decode("invalid-token")
    end
  end
end