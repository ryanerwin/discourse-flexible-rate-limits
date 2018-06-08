# name: flexible-rate-limits
# version: 0.1
# author: Muhlis Budi Cahyono (muhlisbc@gmail.com)
# url: https://github.com/ryanerwin/discourse-flexible-rate-limits

enabled_site_setting :flexible_rate_limits_enabled

register_asset "stylesheets/flexible-rate-limits.scss"

add_admin_route "flexible_rate_limits.admin.nav_label", "flexible-rate-limits"

after_initialize {

  class ::FlexibleRateLimits

    attr_reader :topic_limit, :post_limit, :category_group_name

    def initialize(user, category_id)
      category_groups = PluginStore.get("flexible_rate_limits", "category_groups")
      return if !category_groups.present?
      return if user.blank?

      category_group = category_groups.find { |cg| cg["categories"].include?(category_id) }

      return if category_group.blank?

      @category_group_name = category_group["name"]

      group_ids = user.groups.pluck(:id)

      group = (category_group["groups"] || []).find { |g| group_ids.include?(g["id"]) }

      @topic_limit, @post_limit = (group || category_group).slice("topic_limit", "post_limit").values
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
          category_groups: PluginStore.get("flexible_rate_limits", "category_groups") || [],
          site_settings: fetch_site_settings
        }
      end

      def fetch_site_settings
        keys = %w(
          unique_posts_mins
          rate_limit_create_topic
          rate_limit_create_post
          rate_limit_new_user_create_topic
          rate_limit_new_user_create_post
          max_topics_per_day
          max_topics_in_first_day
          max_replies_in_first_day
          newuser_max_replies_per_topic
        )

        keys.map do |k|
          {
            name: k,
            value: SiteSetting.send(k),
            description: I18n.t("site_settings.#{k}")
          }
        end
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
            RateLimiter.new(self.user, "cg-#{frl.category_group_name}-topic", frl.topic_limit, 1.day.to_i)
          else
            apply_per_day_rate_limit_for("topics", :max_topics_per_day)
          end
        else
          apply_per_day_rate_limit_for("topics", :max_topics_per_day)
        end
      end
    end
  }

  Post.class_eval {
    alias_method :orig_limit_posts_per_day, :limit_posts_per_day

    def limit_posts_per_day
      return if !user
      return if (!post_number || post_number <= 1)
      return orig_limit_posts_per_day if !SiteSetting.flexible_rate_limits_enabled

      return default_limit if user.new_user_posting_on_first_day?

      frl = FlexibleRateLimits.new(self.user, self.topic&.category_id) # int or nil

      if frl.category_group_name
        RateLimiter.new(self.user, "cg-#{frl.category_group_name}-post", frl.post_limit, 1.day.to_i)
      end
    end

    def default_limit
      RateLimiter.new(user, "first-day-replies-per-day", SiteSetting.max_replies_in_first_day, 1.day.to_i)
    end
  }
}