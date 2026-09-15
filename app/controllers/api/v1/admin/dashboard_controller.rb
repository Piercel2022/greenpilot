module Api
  module V1
    module Admin
      class DashboardController < BaseController
        def show
          authorize :admin_dashboard, :show?

          render json: {
            organizations_count: Organization.count,
            users_count: User.count,
            active_subscriptions_count: Subscription.active.count,
            trialing_subscriptions_count: Subscription.trialing.count,
            mrr_cents: calculate_mrr,
            plans: plan_stats,
            recent_organizations: recent_organizations
          }, status: :ok
        end

        private

        def calculate_mrr
          Subscription
            .active
            .joins(:plan)
            .sum("plans.monthly_price_cents")
        end

        def plan_stats
          Plan.active.order(:monthly_price_cents).map do |plan|
            {
              id: plan.id,
              name: plan.name,
              slug: plan.slug,
              subscriptions_count: plan.subscriptions.active.count
            }
          end
        end

        def recent_organizations
          Organization
            .includes(subscription: :plan)
            .order(created_at: :desc)
            .limit(10)
            .map do |organization|
              {
                id: organization.id,
                name: organization.name,
                created_at: organization.created_at,
                subscription: organization.subscription && {
                  status: organization.subscription.status,
                  plan: organization.subscription.plan.name
                }
              }
            end
        end
      end
    end
  end
end