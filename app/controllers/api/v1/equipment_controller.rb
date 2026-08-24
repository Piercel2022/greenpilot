module Api
  module V1
    class EquipmentController < BaseController
      before_action :set_equipment, only: %i[show update destroy]

      def index
        equipment = policy_scope(Equipment)

        render json: equipment
      end

      def show
        authorize @equipment

        render json: @equipment
      end

      def create
        equipment = current_user.organization.equipment.new(equipment_params)

        authorize equipment

        if equipment.save
          render json: equipment, status: :created
        else
          render json: {
            error: "Unprocessable Entity",
            messages: equipment.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      def update
        authorize @equipment

        if @equipment.update(equipment_params)
          render json: @equipment
        else
          render json: {
            error: "Unprocessable Entity",
            messages: @equipment.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      def destroy
        authorize @equipment

        @equipment.destroy!

        head :no_content
      end

      private

      def set_equipment
        @equipment = policy_scope(Equipment).find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: {
          error: "Not Found",
          message: "Equipment not found."
        }, status: :not_found
      end

      def equipment_params
        params.require(:equipment).permit(
          :name,
          :equipment_type,
          :brand,
          :model,
          :serial_number,
          :status,
          :purchase_date,
          :purchase_price,
          :maintenance_interval_days,
          :last_maintenance_at,
          :next_maintenance_at,
          :notes,
          :active
        )
      end
    end
  end
end