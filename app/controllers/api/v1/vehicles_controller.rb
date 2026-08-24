module Api
  module V1
    class VehiclesController < BaseController
      before_action :set_vehicle, only: %i[show update destroy]

      def index
        vehicles = policy_scope(Vehicle)

        render json: vehicles
      end

      def show
        authorize @vehicle

        render json: @vehicle
      end

      def create
        vehicle = current_user.organization.vehicles.new(vehicle_params)

        authorize vehicle

        if vehicle.save
          render json: vehicle, status: :created
        else
          render json: {
            error: "Unprocessable Entity",
            messages: vehicle.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      def update
        authorize @vehicle

        if @vehicle.update(vehicle_params)
          render json: @vehicle
        else
          render json: {
            error: "Unprocessable Entity",
            messages: @vehicle.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      def destroy
        authorize @vehicle

        @vehicle.destroy!

        head :no_content
      end

      private

      def set_vehicle
        @vehicle = policy_scope(Vehicle).find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: {
          error: "Not Found",
          message: "Vehicle not found."
        }, status: :not_found
      end

      def vehicle_params
        params.require(:vehicle).permit(
          :name,
          :registration_number,
          :vehicle_type,
          :brand,
          :model,
          :year,
          :fuel_type,
          :fuel_consumption,
          :capacity,
          :notes,
          :active
        )
      end
    end
  end
end