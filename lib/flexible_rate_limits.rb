class FlexibleRateLimits

  attr_reader :topic_limit, :post_limit, :category_group_name

  def initialize(user, category_id)
    @user           = user
    category_groups = PluginStore.get("flexible_rate_limits", "category_groups")

    return if category_groups.blank? || @user.blank?

    category_group  = category_groups.find { |cg| cg["categories"].include?(category_id) }

    return if category_group.blank?

    @category_group_name      = category_group["name"]
    group_ids                 = @user.groups.pluck(:id)
    group                     = (category_group["groups"] || []).find { |g| group_ids.include?(g["id"]) }
    @topic_limit, @post_limit = (group || category_group).slice("topic_limit", "post_limit").values
    @group                    = Group.find(group["id"]) if group
  end

  def stats(limits_type)
    return if !@user

    @new_user = @user.new_user_posting_on_first_day?
    result = { new_user: @new_user }
    result[limits_type.to_sym] = to_stats(*self.send("#{limits_type}_stats"))

    result
  end

  def topic_stats
    if @new_user
      ["max_topics_in_first_day", SiteSetting.max_topics_in_first_day, "first-day-topics-per-day"]
    else
      if @category_group_name
        [group_setting, @topic_limit, "cg-#{@category_group_name}-topic"]
      else
        ["max_topics_per_day", SiteSetting.max_topics_per_day, "topics-per-day"]
      end
    end
  end

  def post_stats
    if @new_user
      ["max_replies_in_first_day", SiteSetting.max_replies_in_first_day, "first-day-replies-per-day"]
    else
      if @category_group_name
        [group_setting, @post_limit, "cg-#{@category_group_name}-post"]
      else
        ["", "∞"]
      end
    end
  end

  def to_stats(setting, max, key = nil)
    rate_limiter = RateLimiter.new(@user, key, max, 1.day.to_i) if key

    {
      setting: setting,
      limit: rate_limiter&.max || "∞",
      remaining: rate_limiter&.remaining || "∞",
      wait: rate_limiter&.wait_seconds
    }    
  end

  def group_setting
    return @category_group_name unless @group
    "#{@category_group_name} - #{@group.name}"
  end

end
