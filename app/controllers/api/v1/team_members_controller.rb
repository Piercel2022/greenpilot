module Api
  module V1
    class TeamMembersController < BaseController
      before_action :set_team
      before_action :set_team_membership, only: %i[update destroy]

      def index
        authorize @team

        memberships = policy_scope(TeamMembership)
          .where(team_id: @team.id)
          .includes(:user)

        render json: memberships.map { |membership| member_json(membership) }
      end

      def create
        team_membership =
          current_user.organization.team_memberships.new(
            team_membership_params
          )

        team_membership.team = @team

        authorize team_membership

        if team_membership.save
          team_membership.reload

          render json: member_json(team_membership), status: :created
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
          @team_membership.reload

          render json: member_json(@team_membership)
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

      def available_members
        authorize @team

        existing_user_ids =
          @team.team_memberships.pluck(:user_id)

        users = current_user.organization.users
          .where(active: true)
          .where.not(id: existing_user_ids)
          .order(:last_name, :first_name)

        render json: users.map { |user| available_member_json(user) }
      end

      private

      def set_team
         team_id = params[:team_id] || params[:id]

         @team = policy_scope(Team).find(team_id)
        rescue ActiveRecord::RecordNotFound
         render json: {
         error: "Not Found",
         message: "Team not found."
        }, status: :not_found
      end

      def set_team_membership
        @team_membership =
          policy_scope(TeamMembership)
            .where(team_id: @team.id)
            .find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: {
          error: "Not Found",
          message: "Team member not found."
        }, status: :not_found
      end

      def team_membership_params
        params.require(:team_membership).permit(
          :user_id,
          :role,
          :active,
          :start_date,
          :end_date
        )
      end

      def member_json(membership)
        user = membership.user

        {
          id: membership.id,
          team_id: membership.team_id,
          user_id: membership.user_id,
          role: membership.role,
          active: membership.active,
          start_date: membership.start_date,
          end_date: membership.end_date,
          user: {
            id: user.id,
            first_name: user.first_name,
            last_name: user.last_name,
            email: user.email,
            phone: user.phone,
            role: user.role,
            active: user.active
          }
        }
      end

      def available_member_json(user)
        {
          id: user.id,
          first_name: user.first_name,
          last_name: user.last_name,
          email: user.email,
          phone: user.phone,
          role: user.role,
          active: user.active
        }
      end
    end
  end
end