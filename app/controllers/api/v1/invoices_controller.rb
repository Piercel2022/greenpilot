module Api
  module V1
    class InvoicesController < BaseController
      before_action :set_invoice, only: %i[show update destroy]

      def index
        invoices = policy_scope(Invoice)

        render json: invoices
      end

      def show
        authorize @invoice

        render json: @invoice
      end

      def create
        invoice = current_user.organization.invoices.new(
          invoice_params
        )

        authorize invoice

        if invoice.save
          render json: invoice, status: :created
        else
          render json: {
            error: "Unprocessable Entity",
            messages: invoice.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      def update
        authorize @invoice

        if @invoice.update(invoice_params)
          render json: @invoice
        else
          render json: {
            error: "Unprocessable Entity",
            messages: @invoice.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      def destroy
        authorize @invoice

        @invoice.destroy!

        head :no_content
      end

      private

      def set_invoice
        @invoice = policy_scope(Invoice).find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: {
          error: "Not Found",
          message: "Invoice not found."
        }, status: :not_found
      end

      def invoice_params
        params.require(:invoice).permit(
          :customer_id,
          :job_id,
          :quote_id,
          :site_id,
          :number,
          :issue_date,
          :due_date,
          :status,
          :subtotal,
          :discount_amount,
          :tax_amount,
          :total_amount,
          :amount_paid,
          :amount_due,
          :paid_at,
          :payment_method,
          :payment_reference,
          :notes
        )
      end
    end
  end
end