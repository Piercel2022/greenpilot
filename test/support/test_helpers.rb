module TestHelpers
  def create_user(organization:, email:, role:)
    User.create!(
      organization: organization,
      email: email,
      first_name: "Test",
      last_name: "User",
      password: "password",
      password_confirmation: "password",
      role: role
    )
  end
end
