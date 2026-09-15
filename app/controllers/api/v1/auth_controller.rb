module Api
  module V1
    class AuthController < BaseController
      skip_before_action :authenticate_user!, only: %i[login register]

      def login
        user = User.find_by(email: login_params[:email])

        unless user&.authenticate(login_params[:password])
          return render json: {
            error: "Unauthorized",
            message: "Invalid email or password."
          }, status: :unauthorized
        end

        unless user.active?
          return render json: {
            error: "Unauthorized",
            message: "User account is inactive."
          }, status: :unauthorized
        end

        token = JwtService.encode(user)

        user.update_column(:last_sign_in_at, Time.current)

        render json: {
          token: token,
          user: user_json(user)
        }, status: :ok
      end

      def register
        organization = nil
        user = nil

        ActiveRecord::Base.transaction do
          organization = Organization.create!(
            name: register_params[:organization_name]
          )

          plan = Plan.find_by!(slug: "starter", active: true)

          organization.create_subscription!(
            plan: plan,
            status: "trialing",
            billing_interval: "monthly",
            trial_ends_at: 14.days.from_now
          )

          user = organization.users.create!(
            email: register_params[:email],
            password: register_params[:password],
            password_confirmation: register_params[:password_confirmation],
            first_name: register_params[:first_name],
            last_name: register_params[:last_name],
            role: :owner
          )
        end

        token = JwtService.encode(user)

        render json: {
          token: token,
          user: user_json(user)
        }, status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: {
          error: "Unprocessable Entity",
          message: "Unable to create account.",
          errors: e.record.errors.to_hash
        }, status: :unprocessable_entity
      end

      def me
        render json: {
          user: user_json(current_user)
        }, status: :ok
      end

      private

      def login_params
        params.permit(:email, :password)
      end

      def register_params
        params.permit(
          :first_name,
          :last_name,
          :organization_name,
          :email,
          :password,
          :password_confirmation
        )
      end

      def user_json(user)
        {
          id: user.id,
          email: user.email,
          first_name: user.first_name,
          last_name: user.last_name,
          phone: user.phone,
          role: user.role,
          organization_id: user.organization_id
        }
      end
    end
  end
end