module Api
  module V1
    class AuthController < BaseController
      skip_before_action :authenticate_user!, only: :login

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

      def me
        render json: {
          user: user_json(current_user)
        }, status: :ok
      end

      private

      def login_params
        params.permit(:email, :password)
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