module Api
  module V1
    class JobsController < BaseController
      before_action :set_job, only: %i[show update destroy]

      def index
        Rails.logger.warn "=== JOB INDEX START ==="
        Rails.logger.warn "ACTION: #{action_name}"
        Rails.logger.warn "METHOD: #{request.request_method}"
        Rails.logger.warn "PATH: #{request.path}"
        Rails.logger.warn "QUERY: #{request.query_string}"
        Rails.logger.warn "PARAMS: #{params.to_unsafe_h.inspect}"

        jobs = policy_scope(Job)

        Rails.logger.warn "SCOPE: #{jobs.to_sql}"

        jobs = jobs.by_date(params[:date]) if params[:date].present?
        jobs = jobs.where(status: params[:status]) if params[:status].present?
        jobs = jobs.where(priority: params[:priority]) if params[:priority].present?

        Rails.logger.warn "FINAL SQL: #{jobs.to_sql}"

        render json: jobs
      end

      def show
        authorize @job

        render json: @job
      end

      def create
        job = current_user.organization.jobs.new(job_params)

        authorize job, :create_base?
        if job.save
          render json: job, status: :created
        else
          render_unprocessable_entity(job)
        end
      end

      def update
        authorize @job

        if @job.update(job_params)
          render json: @job
        else
          render_unprocessable_entity(@job)
        end
      end

      def destroy
        authorize @job

        @job.destroy!

        head :no_content
      end

      private

      def set_job
        @job = policy_scope(Job).find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render_not_found("Job")
      end

      def job_params
        params.require(:job).permit(
          :customer_id,
          :site_id,
          :quote_id,
          :team_id,
          :vehicle_id,
          :title,
          :description,
          :job_type,
          :status,
          :priority,
          :scheduled_date,
          :scheduled_start_at,
          :scheduled_end_at,
          :started_at,
          :completed_at,
          :cancelled_at,
          :cancellation_reason,
          :estimated_duration_minutes,
          :actual_duration_minutes,
          :address,
          :latitude,
          :longitude,
          :travel_distance_km,
          :travel_duration_minutes,
          :customer_notes,
          :internal_notes,
          :weather_notes,
          :weather_risk
        )
      end
    end
  end
end