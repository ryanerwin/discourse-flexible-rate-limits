require_dependency "admin/admin_controller"

class Admin::FlexibleRateLimitsController < Admin::AdminController

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
