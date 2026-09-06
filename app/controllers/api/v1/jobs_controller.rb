
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
                    .includes(:customer, :site)

        Rails.logger.warn "SCOPE: #{jobs.to_sql}"

        jobs = jobs.by_date(params[:date]) if params[:date].present?
        jobs = jobs.where(status: params[:status]) if params[:status].present?
        jobs = jobs.where(priority: params[:priority]) if params[:priority].present?

        Rails.logger.warn "FINAL SQL: #{jobs.to_sql}"

        render json: jobs.map { |job| job_json(job) }
      end

      def show
        authorize @job

        render json: job_json(@job)
      end

      def create
        job = current_user.organization.jobs.new(job_params)

        authorize job, :create_base?

        if job.save
          render json: job_json(job), status: :created
        else
          render_unprocessable_entity(job)
        end
      end

      def update
        authorize @job

        if @job.update(job_params)
          render json: job_json(@job)
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
        @job = policy_scope(Job)
                  .includes(:customer, :site)
                  .find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render_not_found("Job")
      end

      def job_json(job)
        {
          id: job.id,
          organization_id: job.organization_id,

          customer_id: job.customer_id,
          site_id: job.site_id,

          quote_id: job.quote_id,
          team_id: job.team_id,
          vehicle_id: job.vehicle_id,

          title: job.title,
          description: job.description,
          job_type: job.job_type,

          status: job.status,
          priority: job.priority,

          scheduled_date: job.scheduled_date,
          scheduled_start_at: job.scheduled_start_at,
          scheduled_end_at: job.scheduled_end_at,

          started_at: job.started_at,
          completed_at: job.completed_at,
          cancelled_at: job.cancelled_at,
          cancellation_reason: job.cancellation_reason,

          estimated_duration_minutes: job.estimated_duration_minutes,
          actual_duration_minutes: job.actual_duration_minutes,

          address: job.address,
          latitude: job.latitude,
          longitude: job.longitude,

          travel_distance_km: job.travel_distance_km,
          travel_duration_minutes: job.travel_duration_minutes,

          customer_notes: job.customer_notes,
          internal_notes: job.internal_notes,
          weather_notes: job.weather_notes,
          weather_risk: job.weather_risk,

          customer: customer_json(job.customer),
          site: site_json(job.site),

          created_at: job.created_at,
          updated_at: job.updated_at
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
        elsif customer.respond_to?(:first_name) || customer.respond_to?(:last_name)
          [
            customer.try(:first_name),
            customer.try(:last_name)
          ].compact.join(" ").presence
        else
          nil
        end
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