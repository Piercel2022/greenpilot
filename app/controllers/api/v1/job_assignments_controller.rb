module Api
  module V1
    class JobAssignmentsController < BaseController
      before_action :set_job_assignment, only: %i[show update destroy]

      def index
        job_assignments = policy_scope(JobAssignment)

        render json: job_assignments
      end

      def show
        authorize @job_assignment

        render json: @job_assignment
      end

      def create
        job_assignment = current_user.organization.job_assignments.new(
          job_assignment_params
        )

        authorize job_assignment

        if job_assignment.save
          render json: job_assignment, status: :created
        else
          render json: {
            error: "Unprocessable Entity",
            messages: job_assignment.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      def update
        authorize @job_assignment

        if @job_assignment.update(job_assignment_params)
          render json: @job_assignment
        else
          render json: {
            error: "Unprocessable Entity",
            messages: @job_assignment.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      def destroy
        authorize @job_assignment

        @job_assignment.destroy!

        head :no_content
      end

      private

      def set_job_assignment
        @job_assignment = policy_scope(JobAssignment).find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: {
          error: "Not Found",
          message: "Job assignment not found."
        }, status: :not_found
      end

      def job_assignment_params
        params.require(:job_assignment).permit(
          :job_id,
          :user_id,
          :assignment_type,
          :role,
          :active,
          :assigned_at,
          :accepted_at,
          :completed_at,
          :notes
        )
      end
    end
  end
end