module Api
  module V1
    class ContactRequestsController < ApplicationController
      def create
        contact_request = ContactRequest.new(contact_request_params)

        if contact_request.save
          render json: contact_request, status: :created
        else
          render json: {
            error: "Unprocessable Entity",
            messages: contact_request.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      private

      def contact_request_params
        params.require(:contact_request).permit(
          :first_name,
          :last_name,
          :email,
          :company,
          :phone,
          :request_type,
          :message
        )
      end
    end
  end
end