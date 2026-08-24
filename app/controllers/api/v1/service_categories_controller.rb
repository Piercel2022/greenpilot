module Api
  module V1
    class ServiceCategoriesController < BaseController
      before_action :set_service_category, only: %i[show update destroy]

      def index
        service_categories = policy_scope(ServiceCategory).ordered

        render json: service_categories
      end

      def show
        authorize @service_category

        render json: @service_category
      end

      def create
        service_category = current_user.organization.service_categories.new(
          service_category_params
        )

        authorize service_category

        if service_category.save
          render json: service_category, status: :created
        else
          render json: {
            error: "Unprocessable Entity",
            messages: service_category.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      def update
        authorize @service_category

        if @service_category.update(service_category_params)
          render json: @service_category
        else
          render json: {
            error: "Unprocessable Entity",
            messages: @service_category.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      def destroy
        authorize @service_category

        @service_category.destroy!

        head :no_content
      end

      private

      def set_service_category
        @service_category = policy_scope(ServiceCategory).find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: {
          error: "Not Found",
          message: "Service category not found."
        }, status: :not_found
      end

      def service_category_params
        params.require(:service_category).permit(
          :code,
          :name,
          :description,
          :category_type,
          :position,
          :active
        )
      end
    end
  end
end