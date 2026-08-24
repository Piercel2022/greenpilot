module Api
  module V1
    class ServiceItemsController < BaseController
      before_action :set_service_item, only: %i[show update destroy]

      def index
        service_items = policy_scope(ServiceItem).ordered

        render json: service_items
      end

      def show
        authorize @service_item

        render json: @service_item
      end

      def create
        service_item = current_user.organization.service_items.new(
          service_item_params
        )

        authorize service_item

        if service_item.save
          render json: service_item, status: :created
        else
          render json: {
            error: "Unprocessable Entity",
            messages: service_item.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      def update
        authorize @service_item

        if @service_item.update(service_item_params)
          render json: @service_item
        else
          render json: {
            error: "Unprocessable Entity",
            messages: @service_item.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      def destroy
        authorize @service_item

        @service_item.destroy!

        head :no_content
      end

      private

      def set_service_item
        @service_item = policy_scope(ServiceItem).find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: {
          error: "Not Found",
          message: "Service item not found."
        }, status: :not_found
      end

      def service_item_params
        params.require(:service_item).permit(
          :service_category_id,
          :code,
          :name,
          :description,
          :default_quantity,
          :default_unit_price,
          :default_margin_percentage,
          :labor_cost,
          :material_cost,
          :equipment_cost,
          :overhead_cost,
          :estimated_duration_minutes,
          :unit,
          :position,
          :active
        )
      end
    end
  end
end