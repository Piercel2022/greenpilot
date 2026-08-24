module Api
  module V1
    class QuoteItemsController < BaseController
      before_action :set_quote_item, only: %i[show update destroy]

      def index
        quote_items = policy_scope(QuoteItem).ordered

        render json: quote_items
      end

      def show
        authorize @quote_item

        render json: @quote_item
      end

      def create
        quote_item = QuoteItem.new(quote_item_params)

        authorize quote_item

        if quote_item.save
          render json: quote_item, status: :created
        else
          render json: {
            error: "Unprocessable Entity",
            messages: quote_item.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      def update
        authorize @quote_item

        if @quote_item.update(quote_item_params)
          render json: @quote_item
        else
          render json: {
            error: "Unprocessable Entity",
            messages: @quote_item.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      def destroy
        authorize @quote_item

        @quote_item.destroy!

        head :no_content
      end

      private

      def set_quote_item
        @quote_item = policy_scope(QuoteItem).find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: {
          error: "Not Found",
          message: "Quote item not found."
        }, status: :not_found
      end

      def quote_item_params
        params.require(:quote_item).permit(
          :quote_id,
          :service_item_id,
          :description,
          :quantity,
          :unit,
          :unit_price,
          :discount_percentage,
          :tax_rate,
          :position,
          :estimated_duration_minutes,
          :labor_cost,
          :material_cost,
          :equipment_cost,
          :estimated_cost,
          :margin_percentage,
          :margin_amount,
          :subtotal,
          :tax_amount,
          :total_amount
        )
      end
    end
  end
end