# name: flexible-rate-limits
# version: 0.1
# author: Muhlis Budi Cahyono (muhlisbc@gmail.com)
# url: https://github.com/ryanerwin/discourse-flexible-rate-limits

enabled_site_setting :flexible_rate_limits_enabled

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
      render json: serialized_data
    end

    private

      def serialized_data
        group_attrs = [:id, :name, :full_name]
        {
          groups: Group.select(*group_attrs).slice(*group_attrs),
          category_groups: PluginStore.get("flexible_rate_limits", "category_groups")
        }
      end
  end

}