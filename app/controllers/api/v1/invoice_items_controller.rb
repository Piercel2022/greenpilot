module Api
  module V1
    class InvoiceItemsController < BaseController
      before_action :set_invoice_item, only: %i[show update destroy]

      def index
        invoice_items = policy_scope(InvoiceItem)

        render json: invoice_items
      end

      def show
        authorize @invoice_item

        render json: @invoice_item
      end

      def create
        invoice_item = InvoiceItem.new(invoice_item_params)

        authorize invoice_item

        if invoice_item.save
          render json: invoice_item, status: :created
        else
          render json: {
            error: "Unprocessable Entity",
            messages: invoice_item.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      def update
        authorize @invoice_item

        if @invoice_item.update(invoice_item_params)
          render json: @invoice_item
        else
          render json: {
            error: "Unprocessable Entity",
            messages: @invoice_item.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      def destroy
        authorize @invoice_item

        @invoice_item.destroy!

        head :no_content
      end

      private

      def set_invoice_item
        @invoice_item = policy_scope(InvoiceItem).find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: {
          error: "Not Found",
          message: "Invoice item not found."
        }, status: :not_found
      end

      def invoice_item_params
        params.require(:invoice_item).permit(
          :invoice_id,
          :service_item_id,
          :description,
          :unit,
          :quantity,
          :unit_price,
          :discount_percentage,
          :tax_rate,
          :subtotal,
          :tax_amount,
          :total_amount,
          :position
        )
      end
    end
  end
end