# name: flexible-rate-limits
# version: 0.1
# author: Muhlis Budi Cahyono (muhlisbc@gmail.com)
# url: https://github.com/ryanerwin/discourse-flexible-rate-limits

enabled_site_setting :flexible_rate_limits_enabled

register_asset "stylesheets/flexible-rate-limits.scss"

add_admin_route "flexible_rate_limits.admin.nav_label", "flexible-rate-limits"

after_initialize {

  class ::Admin::FlexibleRateLimitsController < ApplicationController

    def index
      respond_to do |f|
        f.html {
          render nothing: true
        }

        f.json {
          render json: serialized_data
        }
      end
    end

    def save
      PluginStore.set("flexible_rate_limits", "category_groups", params[:category_groups]);
      render json: serialized_data
    end

    private

      def serialized_data
        group_attrs = [:id, :name, :full_name]
        {
          groups: Group.where("id > 0").select(*group_attrs).map { |g| g.slice(*group_attrs) },
          category_groups: PluginStore.get("flexible_rate_limits", "category_groups") || []
        }
      end
  end


  Discourse::Application.routes.append {
    scope "/admin/plugins/flexible-rate-limits", constraints: AdminConstraint.new do
      get ""       => "admin/flexible_rate_limits#index"
      post "save"  => "admin/flexible_rate_limits#save"
    end
  }
}