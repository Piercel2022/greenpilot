module Api
  module V1
    class JobTimeEntriesController < BaseController
      before_action :set_job_time_entry, only: %i[show update destroy]

      def index
        job_time_entries = policy_scope(JobTimeEntry)

        render json: job_time_entries
      end

      def show
        authorize @job_time_entry

        render json: @job_time_entry
      end

      def create
        job_time_entry = current_user.organization.job_time_entries.new(
          job_time_entry_params
        )

        authorize job_time_entry

        if job_time_entry.save
          render json: job_time_entry, status: :created
        else
          render json: {
            error: "Unprocessable Entity",
            messages: job_time_entry.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      def update
        authorize @job_time_entry

        if @job_time_entry.update(job_time_entry_params)
          render json: @job_time_entry
        else
          render json: {
            error: "Unprocessable Entity",
            messages: @job_time_entry.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      def destroy
        authorize @job_time_entry

        @job_time_entry.destroy!

        head :no_content
      end

      private

      def set_job_time_entry
        @job_time_entry = policy_scope(JobTimeEntry).find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: {
          error: "Not Found",
          message: "Job time entry not found."
        }, status: :not_found
      end

      def job_time_entry_params
        params.require(:job_time_entry).permit(
          :job_id,
          :user_id,
          :started_at,
          :ended_at,
          :duration_minutes,
          :entry_type,
          :notes
        )
      end
    end
  end
end