# frozen_string_literal: true

# Seed default Yak features
YakFeature.seed do |f|
  f.id = 1
  f.feature_key = "highlight"
  f.feature_name = "Post Highlighting"
  f.description = "Add a colored border and background to your post"
  f.cost = 10
  f.category = "post"
  f.enabled = true
  f.settings = { duration_hours: 168 } # 7 days
end

YakFeature.seed do |f|
  f.id = 2
  f.feature_key = "pin"
  f.feature_name = "Pin Post"
  f.description = "Pin your post to the top of a topic for 24 hours"
  f.cost = 50
  f.category = "post"
  f.enabled = true
  f.settings = { duration_hours: 24 }
end

YakFeature.seed do |f|
  f.id = 3
  f.feature_key = "boost"
  f.feature_name = "Post Boost"
  f.description = "Boost your post in feeds and search for 72 hours"
  f.cost = 25
  f.category = "post"
  f.enabled = true
  f.settings = { duration_hours: 72 }
end
