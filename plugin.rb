# frozen_string_literal: true

# name: discourse-yaks
# about: Virtual currency system for Discourse - earn and spend Yaks on premium features
# version: 0.1.0
# authors: Discourse
# url: https://github.com/discourse/discourse-yaks

enabled_site_setting :yaks_enabled

add_admin_route "yaks.admin.title", "yaks", use_new_show_route: true

register_asset "stylesheets/yaks.scss"

register_svg_icon "gift"
register_svg_icon "dollar-sign"
register_svg_icon "shopping-cart"
register_svg_icon "coins"
register_svg_icon "thumbtack"
register_svg_icon "pencil"
register_svg_icon "trash-can"
register_svg_icon "plus"

after_initialize do
  module ::DiscourseYaks
    PLUGIN_NAME ||= "discourse-yaks"

    class Engine < ::Rails::Engine
      engine_name PLUGIN_NAME
      isolate_namespace DiscourseYaks
    end
  end

  require_relative "app/models/yak_wallet"
  require_relative "app/models/yak_transaction"
  require_relative "app/models/yak_feature"
  require_relative "app/models/yak_feature_use"
  require_relative "app/models/yak_package"
  require_relative "app/services/yak_feature_service"
  require_relative "app/controllers/yaks_controller"
  require_relative "app/controllers/admin/yaks_controller"
  require_relative "app/jobs/regular/expire_yak_feature"
  require_relative "app/jobs/scheduled/cleanup_expired_yak_features"

  # Add yak_balance method to User model
  add_to_class(:user, :yak_balance) do
    wallet = YakWallet.find_by(user_id: id)
    wallet&.balance || 0
  end

  Discourse::Application.routes.append do
    get "/yaks" => "yaks#index"
    get "/yaks/purchase" => "yaks#index"
    post "/yaks/spend" => "yaks#spend"
    post "/yaks/purchase" => "yaks#purchase"

    get "/admin/plugins/yaks/stats" => "admin/yaks#index", constraints: StaffConstraint.new
    post "/admin/plugins/yaks/give" => "admin/yaks#give_yaks", constraints: StaffConstraint.new
    get "/admin/plugins/yaks/transactions" => "admin/yaks#transactions", constraints: StaffConstraint.new
    get "/admin/plugins/yaks/features" => "admin/yaks#features", constraints: StaffConstraint.new
    post "/admin/plugins/yaks/features" => "admin/yaks#create_feature", constraints: StaffConstraint.new
    put "/admin/plugins/yaks/features/:id" => "admin/yaks#update_feature", constraints: StaffConstraint.new
    get "/admin/plugins/yaks/packages" => "admin/yaks#packages", constraints: StaffConstraint.new
    post "/admin/plugins/yaks/packages" => "admin/yaks#create_package", constraints: StaffConstraint.new
    put "/admin/plugins/yaks/packages/:id" => "admin/yaks#update_package", constraints: StaffConstraint.new
    delete "/admin/plugins/yaks/packages/:id" => "admin/yaks#delete_package", constraints: StaffConstraint.new
  end

  add_to_serializer(:current_user, :yak_balance) do
    object.yak_balance || 0
  end

  # Register custom fields
  register_post_custom_field_type("yak_features", :json)

  # Allow custom field in topic view
  topic_view_post_custom_fields_allowlister do |user, topic|
    ["yak_features"]
  end

  # Add yak_features to post serializer
  add_to_serializer(
    :post,
    :yak_features,
    include_condition: -> { object.custom_fields["yak_features"].present? }
  ) do
    object.custom_fields["yak_features"]
  end

  # Seed default features on plugin initialization
  DiscourseEvent.on(:site_setting_changed) do |name, old_value, new_value|
    if name == :yaks_enabled && new_value == true
      YakFeature.seed_default_features
    end
  end

  # Automatically create wallet for new users
  DiscourseEvent.on(:user_created) do |user|
    YakWallet.for_user(user)
  end
end
