# name: flexible-rate-limits
# version: 0.2
# author: Muhlis Budi Cahyono (muhlisbc@gmail.com)
# url: https://github.com/ryanerwin/discourse-flexible-rate-limits

enabled_site_setting :flexible_rate_limits_enabled

register_asset "stylesheets/flexible-rate-limits.scss"
register_asset "stylesheets/desktop/flexible-rate-limits.scss", :desktop
register_asset "stylesheets/mobile/flexible-rate-limits.scss", :mobile

add_admin_route "flexible_rate_limits.admin.nav_label", "flexible-rate-limits"

require_relative "lib/flexible_rate_limits"

after_initialize {

  load File.expand_path("../lib/controllers/flexible_rate_limits_controller.rb", __FILE__)
  load File.expand_path("../lib/controllers/admin/flexible_rate_limits_controller.rb", __FILE__)

  Discourse::Application.routes.append {
    scope("flexible_rate_limits") {
      post "/:category_id/:limits_type" => "flexible_rate_limits#index"
    }

    scope "/admin/plugins/flexible-rate-limits", constraints: AdminConstraint.new do
      get ""       => "admin/flexible_rate_limits#index"
      post "save"  => "admin/flexible_rate_limits#save"
    end
  }

  require_dependency "topic"
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

  require_dependency "post"
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

  require_dependency "rate_limiter"
  RateLimiter.class_eval {

    alias_method :orig_remaining, :remaining
    def remaining
      return orig_remaining if !SiteSetting.flexible_rate_limits_enabled

      arr = redis.lrange(prefixed_key, 0, @max) || []
      t0 = Time.now.to_i
      arr.reject! { |a| (t0 - a.to_i) > @secs }
      @max - arr.size
    end

    alias_method :orig_rate_unlimited?, :rate_unlimited?
    def rate_unlimited?
      return orig_rate_unlimited? if !SiteSetting.flexible_rate_limits_enabled
      !!RateLimiter.disabled?
    end

    def wait_seconds
      seconds_to_wait
    end
  }
}
