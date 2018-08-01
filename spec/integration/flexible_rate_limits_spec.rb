require "rails_helper"

def ps_set(obj)
  PluginStore.set("flexible_rate_limits", "category_groups", obj)
end

def ps_get()
  PluginStore.get("flexible_rate_limits", "category_groups")
end

def gen_title(n)
  "Actually craft beer synth kinfolk trust fund tacos #{n}"
end

def gen_raw(n)
  "Literally lomo vice normcore keytar twee sustainable ethical cold-pressed #{n}"
end

def _create_post(user, topic_id, num, expected, raw = nil)
  expect {
    num.times do |n|
      post = PostCreator.create!(user, { raw: (raw || gen_raw(n)), topic_id: topic_id, skip_jobs: true }) rescue nil
      expect(post&.post_number || 0).to_not eq(1)
    end
  }.to change{Post.count}.by(expected)
end

def _create_topic(user, category_id, num, expected)
  expect {
    num.times do |n|
      PostCreator.create!(user, { title: gen_title(n), raw: gen_raw(n), category: category_id, skip_jobs: true }) rescue nil
    end
  }.to change{Topic.count}.by(expected)
end

def assign_op(topic_id)
  Fabricate(:post, topic_id: topic_id).save!
end

describe("flexible_rate_limits") {
  let!(:group) { Fabricate(:group) }
  let!(:old_user) { Fabricate(:leader) }
  let!(:category) { Fabricate(:category) }
  let!(:other_category) { Fabricate(:category) }
  let!(:new_user) { Fabricate(:newuser) }
  let!(:other_user) { Fabricate(:leader) }
  let!(:topic) { Fabricate(:topic, category_id: category.id) }

  let!(:other_topic) { Fabricate(:topic, category_id: other_category.id) }

  before {
    [topic, other_topic].each do |t|
      PostCreator.create!(old_user, {raw: gen_raw(1), topic_id: t.id, skip_jobs: true })
    end

    RateLimiter.enable
    RateLimiter.clear_all!

    setting = [
      {
        name: "chatty",
        topic_limit: 2,
        post_limit: 7,
        groups: [
          {
            id: group.id,
            topic_limit: 3,
            post_limit: 4
          }
        ],
        categories: [category.id]
      }
    ]
    ps_set(setting)

    SiteSetting.unique_posts_mins = 0 # How many minutes before a user can make a post with the same content again
    SiteSetting.rate_limit_create_topic = 0 # After creating a topic, users must wait (n) seconds before creating another topic
    SiteSetting.rate_limit_create_post = 0 # After posting, users must wait (n) seconds before creating another post.
    SiteSetting.rate_limit_new_user_create_topic = 0 # After creating a topic, new users must wait (n) seconds before creating another topic.
    SiteSetting.rate_limit_new_user_create_post = 0 # After posting, new users must wait (n) seconds before creating another post.
    SiteSetting.max_topics_per_day = 100 # Maximum number of topics a user can create per day
    SiteSetting.max_topics_in_first_day = 100 # The maximum number of topics a user is allowed to create in the 24 hour period after creating their first post
    SiteSetting.max_replies_in_first_day = 100 # The maximum number of replies a user is allowed to create in the 24 hour period after creating their first post
    SiteSetting.newuser_max_replies_per_topic = 100 # Maximum number of replies a new user can make in a single topic until someone replies to them.
  }

  context("category assigned to a category group") {
    context("user member of group") {

      before {
        group.add(old_user)
        group.add(new_user)
      }

      context("new user") {

        context("topic") {

          it("should respect rate_limit_new_user_create_topic") {
            SiteSetting.rate_limit_new_user_create_topic = 100
            _create_topic(new_user, category.id, 4, 1)
          }

          it("should respect max_topics_in_first_day") {
            SiteSetting.max_topics_in_first_day = 2
            _create_topic(new_user, category.id, 5, 2)
          }

        }

        context("post") {

          it("should respect unique_posts_mins") {
            raw = "Pug ennui yolo knausgaard locavore farm-to-table."
            _create_post(new_user, topic.id, 1, 1, raw)
            SiteSetting.unique_posts_mins = 10
            _create_post(new_user, topic.id, 1, 1, raw)
            _create_post(new_user, topic.id, 1, 0, raw)
          }

          it("should respect rate_limit_new_user_create_post") {
            SiteSetting.rate_limit_new_user_create_post = 100
            _create_post(new_user, topic.id, 5, 1)
          }

          it("should respect newuser_max_replies_per_topic") {
            SiteSetting.newuser_max_replies_per_topic = 2
            _create_post(new_user, topic.id, 6, 2)
          }

          it("should respect max_replies_in_first_day") {
            SiteSetting.max_replies_in_first_day = 5
            _create_post(new_user, topic.id, 10, 5)
          }

        }

      }

      context("old user") {

        context("topic") {

          it("should respect rate_limit_create_topic") {
            SiteSetting.rate_limit_create_topic = 100
            _create_topic(old_user, category.id, 10, 1)
          }

          it("should use max_topics_per_day if plugin disabled") {
            SiteSetting.flexible_rate_limits_enabled = false
            SiteSetting.max_topics_per_day = 6
            _create_topic(old_user, category.id, 12, 6)
          }

          it("should use custom rate limit instead of max_topics_per_day if plugin enabled") {
            SiteSetting.flexible_rate_limits_enabled = true
            _create_topic(old_user, category.id, 10, 3)
          }

        }

        context("post") {

          it("should respect rate_limit_create_post") {
            SiteSetting.rate_limit_create_post = 100
            _create_post(old_user, topic.id, 8, 1)
          }

          it("should not be limited if plugin disabled") {
            SiteSetting.flexible_rate_limits_enabled = false
            _create_post(old_user, topic.id, 10, 10)
          }

          it("should use custom rate limit instead of unlimited if plugin enabled") {
            _create_post(old_user, topic.id, 10, 4)
          }

        }

      }

    }

    context("old user but not member of group") {

      context("topic") {
        it("should use max_topics_per_day if plugin disabled") {
          SiteSetting.flexible_rate_limits_enabled = false
          SiteSetting.max_topics_per_day = 8
          _create_topic(other_user, category.id, 20, 8)
        }

        it("should use category_group default topic_limit if plugin enabled") {
          expect(FlexibleRateLimits.new(other_user, category.id).topic_limit).to eq(2)
          _create_topic(other_user, category.id, 3, 2)
        }
      }

      context("post") {
        it("should not be limited if plugin disabled") {
          SiteSetting.flexible_rate_limits_enabled = false
          _create_post(other_user, topic.id, 12, 12)
        }

        it("should use category_group default post_limit") {
          expect(FlexibleRateLimits.new(other_user, category.id).post_limit).to eq(7)
          _create_post(other_user, topic.id, 20, 7)
        }
      }

    }
  }

  context("category not assigned to a category group") {

    context("topic") {
      it("should use default topic limit") {
        expect(FlexibleRateLimits.new(old_user, other_category.id).category_group_name).to eq(nil)
        SiteSetting.max_topics_per_day = 5
        _create_topic(old_user, other_category.id, 10, 5)
      }
    }

    context("post") {
      it("should not be limited") {
        expect(FlexibleRateLimits.new(old_user, other_topic.category_id).post_limit).to eq(nil)
        _create_post(old_user, other_topic.id, 20, 20)
      }
    }

  }

}
