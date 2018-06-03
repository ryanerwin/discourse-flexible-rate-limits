require "rails_helper"

def ps_set(obj)
  PluginStore.set("flexible_rate_limits", "category_groups", obj)
end

def ps_get()
  PluginStore.get("flexible_rate_limits", "category_groups")
end

def create_post(params)
  get "/posts/", params: params, headers: {"X-Requested-With" => "XMLHttpRequest"}
end

def fabricate_group_users(num, username_prefix, group)
  num.times.map do |n|
    user = Fabricate(:user, username: [username_prefix, n].join)
    Fabricate(:group_user, user: user, group: group)
  end
end

describe("Flexible rate limits") {
  let(:group) { Fabricate(:group) }
  let(:category) { Fabricate(:category) }

  before {
    RateLimiter.enable

    setting = [
      {
        name: "Chatty",
        topic_limit: 1,
        post_limit: 3,
        groups: [
          {
            id: group.id,
            topic_limit: 2,
            post_limit: 4
          }
        ],
        categories: [category.id]
      }
    ]
    ps_set(setting)

    # SiteSetting.unique_posts_mins = 0 # How many minutes before a user can make a post with the same content again
    # SiteSetting.rate_limit_create_topic = 0 # After creating a topic, users must wait (n) seconds before creating another topic
    # SiteSetting.rate_limit_create_post = 0 # After posting, users must wait (n) seconds before creating another post.
    # SiteSetting.rate_limit_new_user_create_topic = 0 # After creating a topic, new users must wait (n) seconds before creating another topic.
    # SiteSetting.rate_limit_new_user_create_post = 0 # After posting, new users must wait (n) seconds before creating another post.
    # SiteSetting.max_topics_in_first_day = 0 
  }

  context("topic") {

    context("user member of group") {
      before {
        log_in_user(member)
      }

      it("should use custom rate limit") {

      }

    }

    context("user member of group") {

    }

  }

  context("post") {

  }
}