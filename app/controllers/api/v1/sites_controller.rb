module Api
  module V1
    class SitesController < BaseController
      before_action :set_site, only: %i[show update destroy]

      def index
        sites = policy_scope(Site)

        render json: sites
      end

      def show
        authorize @site

        render json: @site
      end

      def create
        site = current_user.organization.sites.new(site_params)

        authorize site

        if site.save
          render json: site, status: :created
        else
          render json: {
            error: "Unprocessable Entity",
            messages: site.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      def update
        authorize @site

        if @site.update(site_params)
          render json: @site
        else
          render json: {
            error: "Unprocessable Entity",
            messages: @site.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      def destroy
        authorize @site

        @site.destroy!

        head :no_content
      end

      private

      def set_site
        @site = policy_scope(Site).find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: {
          error: "Not Found",
          message: "Site not found."
        }, status: :not_found
      end

      def site_params
        params.require(:site).permit(
          :customer_id,
          :name,
          :site_type,
          :address_line1,
          :address_line2,
          :postal_code,
          :city,
          :country,
          :latitude,
          :longitude,
          :surface_area,
          :notes,
          :active
        )
      end
    end
  end
end