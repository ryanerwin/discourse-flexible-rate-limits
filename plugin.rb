# name: flexible-rate-limits
# version: 0.1
# author: Muhlis Budi Cahyono (muhlisbc@gmail.com)
# url: https://github.com/ryanerwin/discourse-flexible-rate-limits

enabled_site_setting :flexible_rate_limits_enabled

register_asset "stylesheets/flexible-rate-limits.scss"

add_admin_route "flexible_rate_limits.admin.nav_label", "flexible-rate-limits"

after_initialize {

  class ::FlexibleRateLimits

    attr_reader :topic_limit, :category_group_name

    def initialize(user, category_id)
      category_groups = PluginStore.get("flexible_rate_limits", "category_groups")
      return if !category_groups.present?
      return if user.blank?

      category_group = category_groups.find { |cg| cg["categories"].include?(category_id) }

      return if category_group.blank?

      @category_group_name = category_group["name"]

      group_ids = user.groups.pluck(:id)

      group = (category_group["groups"] || []).find { |g| group_ids.include?(g["id"]) }

      @topic_limit = group ? group["topic_limit"] : category_group["topic_limit"]
    end

  end

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

  Topic.class_eval {
    alias_method :orig_limit_topics_per_day, :limit_topics_per_day

    def limit_topics_per_day
      if user && user.new_user_posting_on_first_day?
        limit_first_day_topics_per_day
      else
        if SiteSetting.flexible_rate_limits_enabled
          frl = FlexibleRateLimits.new(self.user, self.category_id)
          if frl.category_group_name
            RateLimiter.new(self.user, "cg-#{frl.category_group_name}-per-day", frl.topic_limit, 1.day.to_i)
          else
            apply_per_day_rate_limit_for("topics", :max_topics_per_day)
          end
        else
          apply_per_day_rate_limit_for("topics", :max_topics_per_day)
        end
      end
    end
  }
}