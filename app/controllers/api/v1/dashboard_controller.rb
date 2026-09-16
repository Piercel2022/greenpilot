module Api
  module V1
    class DashboardController < BaseController
      def show
        render json: {
          kpis: kpis,
          revenue: revenue_data,
          quotes_pipeline: quotes_pipeline_data,
          workload: workload_data,
          billing: billing_data
        }
      end

      private

      def organization_id
        current_user.organization_id
      end

      def kpis
        {
          revenue: current_month_invoices.sum(:total_amount).to_f,
          quotes_pending: quotes
            .where(status: %w[draft sent])
            .sum(:total_amount)
            .to_f,
          active_jobs: jobs.where(status: %w[planned in_progress]).count,
          overdue_amount: invoices
            .where("due_date < ?", Date.current)
            .where("amount_due > 0")
            .sum(:amount_due)
            .to_f
        }
      end

      def revenue_data
        start_date = 11.months.ago.to_date.beginning_of_month
        end_date = Date.current.end_of_month

        invoices
          .where(issue_date: start_date..end_date)
          .group(Arel.sql("DATE_TRUNC('month', issue_date)"))
          .sum(:total_amount)
          .sort_by { |month, _amount| month }
          .map do |month, amount|
            {
              month: month.strftime("%Y-%m"),
              amount: amount.to_f
            }
          end
      end

      def quotes_pipeline_data
        quotes
          .group(:status)
          .sum(:total_amount)
          .map do |status, amount|
            {
              status: status,
              amount: amount.to_f
            }
          end
      end

      def workload_data
        start_date = Date.current.beginning_of_week
        end_date = Date.current.end_of_week

        jobs
          .where(scheduled_date: start_date..end_date)
          .group(:scheduled_date)
          .sum(:estimated_duration_minutes)
          .sort_by { |date, _minutes| date }
          .map do |date, minutes|
            {
              date: date.iso8601,
              hours: (minutes.to_f / 60).round(2)
            }
          end
      end

      def billing_data
        start_date = 11.months.ago.to_date.beginning_of_month
        end_date = Date.current.end_of_month

        invoices
          .where(issue_date: start_date..end_date)
          .group(Arel.sql("DATE_TRUNC('month', issue_date)"))
          .pluck(
            Arel.sql("DATE_TRUNC('month', issue_date)"),
            Arel.sql("SUM(total_amount)"),
            Arel.sql("SUM(amount_paid)")
          )
          .sort_by(&:first)
          .map do |month, invoiced, paid|
            {
              month: month.strftime("%Y-%m"),
              invoiced: invoiced.to_f,
              paid: paid.to_f
            }
          end
      end

      def current_month_invoices
        invoices.where(
          issue_date: Date.current.beginning_of_month..Date.current.end_of_month
        )
      end

      def invoices
        Invoice.where(organization_id: organization_id)
      end

      def quotes
        Quote.where(organization_id: organization_id)
      end

      def jobs
        Job.where(organization_id: organization_id)
      end
    end
  end
end
