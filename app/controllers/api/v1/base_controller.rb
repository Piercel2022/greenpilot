module Api
  module V1
    class BaseController < ApplicationController
      include Pundit::Authorization

      before_action :authenticate_user!

      rescue_from Pundit::NotAuthorizedError, with: :render_forbidden

      private

      attr_reader :current_user

      def authenticate_user!
        token = request.headers["Authorization"]&.split(" ")&.last

        return render_unauthorized("Authentication token is missing.") unless token

        payload = JwtService.decode(token)
        user = User.find_by(id: payload["sub"])

        return render_unauthorized("User not found.") unless user
        return render_unauthorized("User account is inactive.") unless user.active?

        @current_user = user
      rescue JwtService::Error
        render_unauthorized("Invalid or expired authentication token.")
      end

      def render_unauthorized(message)
        render json: {
          error: "Unauthorized",
          message: message
        }, status: :unauthorized
      end

      def render_forbidden
        render json: {
          error: "Forbidden",
          message: "You are not authorized to perform this action."
        }, status: :forbidden
      end

      def render_not_found(resource = "Resource")
        render json: {
          error: "Not Found",
          message: "#{resource} not found."
        }, status: :not_found
      end

      def render_unprocessable_entity(record)
        render json: {
          error: "Unprocessable Entity",
          messages: record.errors.full_messages
        }, status: :unprocessable_entity
      end
    end
  end
end
