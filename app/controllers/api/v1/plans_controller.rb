module Api
  module V1
    class PlansController < BaseController
      skip_before_action :authenticate_user!

      def index
        plans = Plan.active.order(:monthly_price_cents)

        render json: plans.map { |plan| plan_json(plan) }, status: :ok
      end

      private

      def plan_json(plan)
        {
          id: plan.id,
          name: plan.name,
          slug: plan.slug,
          monthly_price_cents: plan.monthly_price_cents,
          yearly_price_cents: plan.yearly_price_cents,
          max_users: plan.max_users
        }
      end
    end
  end
end
