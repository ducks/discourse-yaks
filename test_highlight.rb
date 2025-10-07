# frozen_string_literal: true

# Test script to enable Yaks and highlight a post
# Run with: bin/rails runner plugins/discourse-yaks/test_highlight.rb TOPIC_ID POST_NUMBER [COLOR]
# Example: bin/rails runner plugins/discourse-yaks/test_highlight.rb 11735 2 gold

puts "🦬 Testing Discourse Yaks Plugin..."

# Parse arguments
topic_id = ARGV[0]&.to_i
post_number = ARGV[1]&.to_i || 1
color = ARGV[2] || 'gold'

if topic_id.nil? || topic_id == 0
  puts "Usage: bin/rails runner plugins/discourse-yaks/test_highlight.rb TOPIC_ID POST_NUMBER [COLOR]"
  puts "Example: bin/rails runner plugins/discourse-yaks/test_highlight.rb 11735 2 gold"
  puts "Colors: gold, blue, red, green, purple"
  exit 1
end

# Enable the plugin
SiteSetting.yaks_enabled = true
puts "✓ Plugin enabled"

# Get first user (usually admin)
user = User.where(admin: true).first || User.first
puts "✓ Using user: #{user.username} (ID: #{user.id})"

# Get specific post
topic = Topic.find_by(id: topic_id)
if topic.nil?
  puts "✗ Topic #{topic_id} not found!"
  exit 1
end

post = topic.posts.find_by(post_number: post_number)
if post.nil?
  puts "✗ Post ##{post_number} not found in topic #{topic_id}!"
  exit 1
end
puts "✓ Found post: #{post.id} in topic '#{post.topic.title}' (post ##{post_number})"

# Create or get wallet
wallet = YakWallet.for_user(user)
puts "✓ Wallet found/created - Balance: #{wallet.balance}"

# Grant Yaks if needed
if wallet.balance < 100
  wallet.add_yaks(100, 'admin_grant', 'Testing Yaks plugin')
  puts "✓ Granted 100 Yaks - New balance: #{wallet.balance}"
else
  puts "✓ User already has #{wallet.balance} Yaks"
end

# Apply highlight feature to the post
result = YakFeatureService.apply_feature(
  user,
  'post_highlight',
  related_post: post,
  feature_data: { color: color }
)

if result[:success]
  puts "✓ Highlight applied successfully!"
  puts "  - New balance: #{result[:new_balance]}"
  puts "  - Feature use ID: #{result[:feature_use].id}"
  puts "\n🎉 Success! Visit your Discourse site and view post ##{post.id}"
  puts "   URL: http://localhost:3000/t/#{post.topic.slug}/#{post.topic_id}/#{post.post_number}"
else
  puts "✗ Failed to apply highlight: #{result[:error]}"
  exit 1
end
