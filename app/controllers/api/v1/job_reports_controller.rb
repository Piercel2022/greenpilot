module Api
  module V1
    class JobReportsController < BaseController
      before_action :set_job_report, only: %i[show update destroy]

      def index
        job_reports = policy_scope(JobReport)
                        .includes(job: %i[customer site])

        render json: job_reports.map { |job_report| job_report_json(job_report) }
      end

      def show
        authorize @job_report

        render json: job_report_json(@job_report)
      end

      def create
        job_report = current_user.organization.job_reports.new(
          job_report_params
        )

        authorize job_report

        if job_report.save
          render json: job_report_json(job_report), status: :created
        else
          render_unprocessable_entity(job_report)
        end
      end

      def update
        authorize @job_report

        if @job_report.update(job_report_params)
          render json: job_report_json(@job_report)
        else
          render_unprocessable_entity(@job_report)
        end
      end

      def destroy
        authorize @job_report

        @job_report.destroy!

        head :no_content
      end

      private

      def set_job_report
        @job_report = policy_scope(JobReport)
                      .includes(job: %i[customer site])
                      .find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render_not_found("JobReport")
      end

      def job_report_json(job_report)
        {
          id: job_report.id,
          organization_id: job_report.organization_id,
          job_id: job_report.job_id,

          summary: job_report.summary,
          work_performed: job_report.work_performed,
          observations: job_report.observations,
          recommendations: job_report.recommendations,

          customer_signature: job_report.customer_signature,
          customer_signed_at: job_report.customer_signed_at,

          generated_at: job_report.generated_at,
          sent_to_customer_at: job_report.sent_to_customer_at,

          job: job_json(job_report.job),

          created_at: job_report.created_at,
          updated_at: job_report.updated_at
        }
      end

      def job_json(job)
        return nil unless job

        {
          id: job.id,
          title: job.title,
          status: job.status,
          scheduled_date: job.scheduled_date,

          customer: customer_json(job.customer),
          site: site_json(job.site)
        }
      end

      def customer_json(customer)
        return nil unless customer

        {
          id: customer.id,
          name: customer_name(customer)
        }
      end

      def site_json(site)
        return nil unless site

        {
          id: site.id,
          name: site.name,
          address: site.try(:address)
        }
      end

      def customer_name(customer)
        if customer.respond_to?(:name) && customer.name.present?
          customer.name
        elsif customer.respond_to?(:company_name) && customer.company_name.present?
          customer.company_name
        elsif customer.respond_to?(:first_name) ||
              customer.respond_to?(:last_name)
          [
            customer.try(:first_name),
            customer.try(:last_name)
          ].compact.join(" ").presence
        else
          nil
        end
      end

      def job_report_params
        params.require(:job_report).permit(
          :job_id,
          :summary,
          :work_performed,
          :observations,
          :recommendations,
          :generated_at,
          :sent_to_customer_at,
          :customer_signature,
          :customer_signed_at
        )
      end
    end
  end
end