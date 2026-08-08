# frozen_string_literal: true

# name: discourse-yaks
# about: Non-monetary community currency for earning and spending Yaks on forum perks
# version: 20260802
# authors: ducks
# url: https://github.com/ducks/discourse-yaks
# required_version: 3.4.0
# license: GPL-2.0-or-later

enabled_site_setting :yaks_enabled

add_admin_route "yaks.admin.title", "yaks", use_new_show_route: true

register_asset "stylesheets/yaks.scss"

register_svg_icon "gift"
register_svg_icon "coins"
register_svg_icon "thumbtack"
register_svg_icon "pencil"
register_svg_icon "trash-can"
register_svg_icon "plus"
register_svg_icon "star"
register_svg_icon "heart"
register_svg_icon "fire"
register_svg_icon "bolt"
register_svg_icon "gem"
register_svg_icon "crown"
register_svg_icon "rocket"
register_svg_icon "trophy"

after_initialize do
  module ::DiscourseYaks
    PLUGIN_NAME = "discourse-yaks"

    class Engine < ::Rails::Engine
      engine_name PLUGIN_NAME
      isolate_namespace DiscourseYaks
    end
  end

  require_relative "app/models/yak_wallet"
  require_relative "app/models/yak_transaction"
  require_relative "app/models/yak_feature"
  require_relative "app/models/yak_feature_use"
  require_relative "app/services/yak_feature_service"
  require_relative "app/controllers/yaks_controller"
  require_relative "app/controllers/admin/yaks_controller"
  require_relative "app/jobs/regular/expire_yak_feature"
  require_relative "app/jobs/scheduled/cleanup_expired_yak_features"
  require_relative "app/services/yak_earning_service"
  require_relative "app/models/yak_earning_rule"

  Discourse::Application.routes.append do
    get "/yaks" => "yaks#index"
    get "/yaks/catalog" => "yaks#catalog"
    post "/yaks/spend" => "yaks#spend"

    get "/admin/plugins/yaks/stats" => "admin/yaks#stats", :constraints => StaffConstraint.new
    post "/admin/plugins/yaks/give" => "admin/yaks#give_yaks", :constraints => StaffConstraint.new
    get "/admin/plugins/yaks/transactions" => "admin/yaks#transactions",
        :constraints => StaffConstraint.new
    get "/admin/plugins/yaks/features" => "admin/yaks#features", :constraints => StaffConstraint.new
    put "/admin/plugins/yaks/features/:id" => "admin/yaks#update_feature",
        :constraints => StaffConstraint.new
    get "/admin/plugins/yaks/earning_rules" => "admin/yaks#earning_rules",
        :constraints => StaffConstraint.new
    put "/admin/plugins/yaks/earning_rules/:id" => "admin/yaks#update_earning_rule",
        :constraints => StaffConstraint.new
  end

  add_to_serializer(:current_user, :yak_balance) { object.yak_balance || 0 }

  # Register custom fields
  register_post_custom_field_type("yak_features", :json)
  register_topic_custom_field_type("yak_features", :json)
  register_user_custom_field_type("yak_features", :json)

  # Allow custom field in topic view
  topic_view_post_custom_fields_allowlister { |user, topic| ["yak_features"] }

  # Add yak_features to post serializer
  add_to_serializer(
    :post,
    :yak_features,
    include_condition: -> { object.custom_fields["yak_features"].present? },
  ) { object.custom_fields["yak_features"] }

  # Add yak_features to topic list item serializer
  add_to_serializer(
    :topic_list_item,
    :yak_features,
    include_condition: -> { object.custom_fields["yak_features"].present? },
  ) { object.custom_fields["yak_features"] }

  # Add yak_features to topic view serializer
  add_to_serializer(
    :topic_view,
    :yak_features,
    include_condition: -> { object.topic.custom_fields["yak_features"].present? },
  ) { object.topic.custom_fields["yak_features"] }

  # Preload topic custom fields to avoid N+1 queries
  if TopicList.respond_to?(:preloaded_custom_fields)
    TopicList.preloaded_custom_fields << "yak_features"
  end
  Topic.preloaded_custom_fields << "yak_features" if Topic.respond_to?(:preloaded_custom_fields)

  # Preload user custom fields for flair
  User.preloaded_custom_fields << "yak_features" if User.respond_to?(:preloaded_custom_fields)

  # Override flair fields with yak custom flair if present
  %i[post user_card post_action_user].each do |serializer_name|
    # Set a dummy flair_group_id so the frontend component renders flair
    add_to_serializer(serializer_name, :flair_group_id) do
      begin
        user = serializer_name == :post ? object.user : object
        flair = user.custom_fields["yak_features"]&.dig("flair")
        if flair && flair["enabled"]
          # Return -1 as a marker for "yak custom flair" (not a real group)
          -1
        else
          user.flair_group_id
        end
      rescue => e
        Rails.logger.error("Error in flair_group_id serializer: #{e.message}")
        user = serializer_name == :post ? object.user : object
        user.flair_group_id
      end
    end

    add_to_serializer(serializer_name, :flair_url) do
      begin
        user = serializer_name == :post ? object.user : object
        flair = user.custom_fields["yak_features"]&.dig("flair")
        if flair && flair["enabled"]
          flair["icon"]
        else
          user.flair_group&.flair_icon || user.flair_group&.flair_upload&.url
        end
      rescue => e
        Rails.logger.error("Error in flair_url serializer: #{e.message}")
        user = serializer_name == :post ? object.user : object
        user.flair_group&.flair_icon || user.flair_group&.flair_upload&.url
      end
    end

    add_to_serializer(serializer_name, :flair_bg_color) do
      begin
        user = serializer_name == :post ? object.user : object
        flair = user.custom_fields["yak_features"]&.dig("flair")
        if flair && flair["enabled"]
          flair["bg_color"]
        else
          user.flair_group&.flair_bg_color
        end
      rescue => e
        Rails.logger.error("Error in flair_bg_color serializer: #{e.message}")
        user = serializer_name == :post ? object.user : object
        user.flair_group&.flair_bg_color
      end
    end

    add_to_serializer(serializer_name, :flair_color) do
      begin
        user = serializer_name == :post ? object.user : object
        flair = user.custom_fields["yak_features"]&.dig("flair")
        if flair && flair["enabled"]
          flair["color"]
        else
          user.flair_group&.flair_color
        end
      rescue => e
        Rails.logger.error("Error in flair_color serializer: #{e.message}")
        user = serializer_name == :post ? object.user : object
        user.flair_group&.flair_color
      end
    end

    add_to_serializer(serializer_name, :flair_name) do
      begin
        user = serializer_name == :post ? object.user : object
        flair = user.custom_fields["yak_features"]&.dig("flair")
        if flair && flair["enabled"]
          "yak-flair"
        else
          user.flair_group&.name
        end
      rescue => e
        Rails.logger.error("Error in flair_name serializer: #{e.message}")
        user = serializer_name == :post ? object.user : object
        user.flair_group&.name
      end
    end

    # Override title with yak custom title if present
    add_to_serializer(serializer_name, :title) do
      begin
        user = serializer_name == :post ? object.user : object
        title_data = user.custom_fields["yak_features"]&.dig("title")
        if title_data && title_data["enabled"]
          title_data["text"]
        else
          user.title
        end
      rescue => e
        Rails.logger.error("Error in title serializer: #{e.message}")
        user = serializer_name == :post ? object.user : object
        user.title
      end
    end
  end

  # Override title in additional serializers
  %i[user_name group_post_user group_user hidden_profile].each do |serializer_name|
    add_to_serializer(serializer_name, :title) do
      begin
        title_data = object.custom_fields["yak_features"]&.dig("title")
        if title_data && title_data["enabled"]
          title_data["text"]
        else
          object.title
        end
      rescue => e
        Rails.logger.error("Error in title serializer (#{serializer_name}): #{e.message}")
        object.title
      end
    end
  end

  # Override user_title in post serializer (this is what shows next to posts)
  add_to_serializer(:post, :user_title) do
    begin
      user = object&.user
      return nil unless user

      title_data = user.custom_fields["yak_features"]&.dig("title")
      if title_data && title_data["enabled"]
        title_data["text"]
      else
        user.title
      end
    rescue => e
      Rails.logger.error("Error in user_title serializer: #{e.message}")
      object&.user&.title
    end
  end

  # Seed default features on plugin initialization
  on(:site_setting_changed) do |name, _old_value, new_value|
    YakFeature.seed_default_features if name == :yaks_enabled && new_value == true
  end

  # Earning system event hooks
  on(:post_created) do |post, _opts, _user|
    next if post.post_type != Post.types[:regular]
    # Discourse emits both topic_created and post_created for a topic's first
    # post. Reward it through the more valuable topic rule only, otherwise a
    # new topic silently earns both configured amounts.
    next if post.is_first_post?
    next if post.deleted_at.present?
    next if post.hidden
    next if !post.user

    YakEarningService.award(
      user: post.user,
      action_key: "post_created",
      related_post: post,
      related_topic: post.topic,
      event_id: post.id,
    )
  end

  on(:topic_created) do |topic, _opts, _user|
    next if topic.deleted_at.present?
    next if !topic.visible
    next if !topic.user

    YakEarningService.award(
      user: topic.user,
      action_key: "topic_created",
      related_topic: topic,
      event_id: topic.id,
    )
  end

  on(:like_created) do |post_action|
    post = post_action.post
    next if !post
    next if post.deleted_at.present?
    next if post.hidden
    next if post.user_id == post_action.user_id # Don't reward self-likes

    YakEarningService.award(
      user: post.user,
      action_key: "post_liked",
      related_post: post,
      related_topic: post.topic,
      event_id: "#{post.id}:#{post_action.user_id}",
    )
  end

  # Hook for discourse-solved plugin (if installed)
  on(:accepted_solution) do |post|
    next if !post
    next if post.deleted_at.present?
    next if post.hidden

    YakEarningService.award(
      user: post.user,
      action_key: "solution_accepted",
      related_post: post,
      related_topic: post.topic,
      event_id: post.id,
    )
  end
end
