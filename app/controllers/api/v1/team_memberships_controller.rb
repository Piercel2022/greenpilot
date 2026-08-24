module Api
  module V1
    class TeamMembershipsController < BaseController
      before_action :set_team_membership, only: %i[show update destroy]

      def index
        team_memberships = policy_scope(TeamMembership)

        render json: team_memberships
      end

      def show
        authorize @team_membership

        render json: @team_membership
      end

      def create
        team_membership =
          current_user.organization.team_memberships.new(
            team_membership_params
          )

        authorize team_membership

        if team_membership.save
          render json: team_membership, status: :created
        else
          render json: {
            error: "Unprocessable Entity",
            messages: team_membership.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      def update
        authorize @team_membership

        if @team_membership.update(team_membership_params)
          render json: @team_membership
        else
          render json: {
            error: "Unprocessable Entity",
            messages: @team_membership.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      def destroy
        authorize @team_membership

        @team_membership.destroy!

        head :no_content
      end

      private

      def set_team_membership
        @team_membership = policy_scope(TeamMembership).find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: {
          error: "Not Found",
          message: "Team membership not found."
        }, status: :not_found
      end

      def team_membership_params
        params.require(:team_membership).permit(
          :team_id,
          :user_id,
          :role,
          :active,
          :start_date,
          :end_date
        )
      end
    end
  end
end