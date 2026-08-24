module Api
  module V1
    class JobReportsController < BaseController
      before_action :set_job_report, only: %i[show update destroy]

      def index
        job_reports = policy_scope(JobReport)

        render json: job_reports
      end

      def show
        authorize @job_report

        render json: @job_report
      end

      def create
        job_report = current_user.organization.job_reports.new(
          job_report_params
        )

        authorize job_report

        if job_report.save
          render json: job_report, status: :created
        else
          render json: {
            error: "Unprocessable Entity",
            messages: job_report.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      def update
        authorize @job_report

        if @job_report.update(job_report_params)
          render json: @job_report
        else
          render json: {
            error: "Unprocessable Entity",
            messages: @job_report.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      def destroy
        authorize @job_report

        @job_report.destroy!

        head :no_content
      end

      private

      def set_job_report
        @job_report = policy_scope(JobReport).find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: {
          error: "Not Found",
          message: "Job report not found."
        }, status: :not_found
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