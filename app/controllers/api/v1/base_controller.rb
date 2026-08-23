module Api
  module V1
    class BaseController < ApplicationController
      include Pundit::Authorization

      before_action :authenticate_user!

      rescue_from Pundit::NotAuthorizedError, with: :render_forbidden

      private

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