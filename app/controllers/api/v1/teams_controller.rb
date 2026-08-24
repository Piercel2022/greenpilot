module Api
  module V1
    class TeamsController < BaseController
      before_action :set_team, only: %i[show update destroy]

      def index
        teams = policy_scope(Team)

        render json: teams
      end

      def show
        authorize @team

        render json: @team
      end

      def create
        team = current_user.organization.teams.new(team_params)

        authorize team

        if team.save
          render json: team, status: :created
        else
          render json: {
            error: "Unprocessable Entity",
            messages: team.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      def update
        authorize @team

        if @team.update(team_params)
          render json: @team
        else
          render json: {
            error: "Unprocessable Entity",
            messages: @team.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      def destroy
        authorize @team

        @team.destroy!

        head :no_content
      end

      private

      def set_team
        @team = policy_scope(Team).find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: {
          error: "Not Found",
          message: "Team not found."
        }, status: :not_found
      end

      def team_params
        params.require(:team).permit(
          :code,
          :name,
          :description,
          :color,
          :active
        )
      end
    end
  end
end