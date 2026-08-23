module Api
  module V1
    class CustomersController < BaseController
      before_action :set_customer, only: %i[show update destroy]

      def index
        customers = policy_scope(Customer)

        render json: customers
      end

      def show
        authorize @customer

        render json: @customer
      end

      def create
        customer = current_user.organization.customers.new(customer_params)

        authorize customer

        if customer.save
          render json: customer, status: :created
        else
          render json: {
            error: "Unprocessable Entity",
            messages: customer.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      def update
        authorize @customer

        if @customer.update(customer_params)
          render json: @customer
        else
          render json: {
            error: "Unprocessable Entity",
            messages: @customer.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      def destroy
        authorize @customer

        @customer.destroy!

        head :no_content
      end

      private

      def set_customer
        @customer = policy_scope(Customer).find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: {
          error: "Not Found",
          message: "Customer not found."
        }, status: :not_found
      end

      def customer_params
        params.require(:customer).permit(
          :customer_type,
          :company_name,
          :first_name,
          :last_name,
          :email,
          :phone,
          :mobile,
          :notes,
          :active
        )
      end
    end
  end
end