module Api
  module V1
    class QuotesController < BaseController
      before_action :set_quote, only: %i[show update destroy]

      def index
        quotes = policy_scope(Quote)

        render json: quotes
      end

      def show
        authorize @quote

        render json: @quote
      end

      def create
        quote = current_user.organization.quotes.new(quote_params)

        authorize quote

        if quote.save
          render json: quote, status: :created
        else
          render json: {
            error: "Unprocessable Entity",
            messages: quote.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      def update
        authorize @quote

        if @quote.update(quote_params)
          render json: @quote
        else
          render json: {
            error: "Unprocessable Entity",
            messages: @quote.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      def destroy
        authorize @quote

        @quote.destroy!

        head :no_content
      end

      private

      def set_quote
        @quote = policy_scope(Quote).find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: {
          error: "Not Found",
          message: "Quote not found."
        }, status: :not_found
      end

      def quote_params
        params.require(:quote).permit(
          :customer_id,
          :site_id,
          :number,
          :title,
          :description,
          :issue_date,
          :valid_until,
          :status,
          :notes,
          :discount_amount,
          :estimated_cost,
          :estimated_margin_percentage,
          :estimated_margin_amount,
          :subtotal,
          :tax_amount,
          :total_amount,
          :accepted_at,
          :rejected_at
        )
      end
    end
  end
end