# frozen_string_literal: true

RSpec.describe YakEarningService do
  fab!(:user) { Fabricate(:user, trust_level: 1) }
  fab!(:tl0_user) { Fabricate(:user, trust_level: 0) }

  before do
    SiteSetting.yaks_enabled = true
    # Ensure earning rules exist
    YakFeature.seed_default_features
  end

  describe ".award" do
    context "post_created" do
      it "awards Yaks for valid post by TL1 user" do
        post = Fabricate(:post, user: user, raw: "This is a test post with more than twenty characters")

        result =
          YakEarningService.award(
            user: post.user,
            action_key: "post_created",
            related_post: post,
            related_topic: post.topic,
          )

        expect(result).to eq(true)
        expect(user.reload.yak_balance).to eq(2)

        # Check transaction was created
        wallet = YakWallet.find_by(user: user)
        transaction = wallet.yak_transactions.last
        expect(transaction.transaction_type).to eq("earn")
        expect(transaction.amount).to eq(2)
        expect(transaction.description).to eq("Earned from: Post Created")
      end

      it "does not award Yaks to TL0 user" do
        post =
          Fabricate(:post, user: tl0_user, raw: "This is a test post with more than twenty characters")

        result =
          YakEarningService.award(
            user: post.user,
            action_key: "post_created",
            related_post: post,
            related_topic: post.topic,
          )

        expect(result).to eq(false)
        expect(tl0_user.reload.yak_balance).to eq(0)
      end

      it "does not award Yaks for post under 20 characters" do
        post = Fabricate(:post, user: user, raw: "Short post")

        result =
          YakEarningService.award(
            user: post.user,
            action_key: "post_created",
            related_post: post,
            related_topic: post.topic,
          )

        expect(result).to eq(false)
        expect(user.reload.yak_balance).to eq(0)
      end

      it "respects daily cap" do
        rule = YakEarningRule.find_by(action_key: "post_created")
        daily_cap = rule.daily_cap

        # Create posts up to daily cap
        daily_cap.times do |i|
          post = Fabricate(:post, user: user, raw: "Post number #{i} with enough characters here")

          result =
            YakEarningService.award(
              user: post.user,
              action_key: "post_created",
              related_post: post,
              related_topic: post.topic,
            )

          expect(result).to eq(true)
        end

        # Next post should fail due to cap
        post =
          Fabricate(
            :post,
            user: user,
            raw: "This post exceeds the daily cap and should not earn",
          )

        result =
          YakEarningService.award(
            user: post.user,
            action_key: "post_created",
            related_post: post,
            related_topic: post.topic,
          )

        expect(result).to eq(false)
        expect(user.reload.yak_balance).to eq(daily_cap * 2) # 2 Yaks per post
      end
    end

    context "topic_created" do
      it "awards Yaks for valid topic by TL1 user" do
        topic = Fabricate(:topic, user: user)
        post =
          Fabricate(
            :post,
            user: user,
            topic: topic,
            raw: "This is a topic with more than fifty characters in it for testing purposes",
          )

        result =
          YakEarningService.award(
            user: topic.user,
            action_key: "topic_created",
            related_topic: topic,
          )

        expect(result).to eq(true)
        expect(user.reload.yak_balance).to eq(5)
      end

      it "does not award Yaks for topic under 50 characters" do
        topic = Fabricate(:topic, user: user)
        post = Fabricate(:post, user: user, topic: topic, raw: "Short topic content")

        result =
          YakEarningService.award(
            user: topic.user,
            action_key: "topic_created",
            related_topic: topic,
          )

        expect(result).to eq(false)
        expect(user.reload.yak_balance).to eq(0)
      end
    end

    context "post_liked" do
      it "awards Yaks when post receives like" do
        post = Fabricate(:post, user: user, raw: "A likeable post with content")
        liker = Fabricate(:user)

        result =
          YakEarningService.award(
            user: post.user,
            action_key: "post_liked",
            related_post: post,
            related_topic: post.topic,
          )

        expect(result).to eq(true)
        expect(user.reload.yak_balance).to eq(3)
      end
    end

    context "solution_accepted" do
      it "awards Yaks when post marked as solution" do
        post = Fabricate(:post, user: user, raw: "This is the solution")

        result =
          YakEarningService.award(
            user: post.user,
            action_key: "solution_accepted",
            related_post: post,
            related_topic: post.topic,
          )

        expect(result).to eq(true)
        expect(user.reload.yak_balance).to eq(25)
      end

      it "has no daily cap" do
        rule = YakEarningRule.find_by(action_key: "solution_accepted")
        expect(rule.has_daily_cap?).to eq(false)

        # Should be able to earn multiple times
        5.times do
          post = Fabricate(:post, user: user, raw: "Another solution")

          result =
            YakEarningService.award(
              user: post.user,
              action_key: "solution_accepted",
              related_post: post,
              related_topic: post.topic,
            )

          expect(result).to eq(true)
        end

        expect(user.reload.yak_balance).to eq(125) # 25 * 5
      end
    end

    context "with disabled rule" do
      it "does not award Yaks when rule is disabled" do
        rule = YakEarningRule.find_by(action_key: "post_created")
        rule.update!(enabled: false)

        post = Fabricate(:post, user: user, raw: "Post with disabled earning rule")

        result =
          YakEarningService.award(
            user: post.user,
            action_key: "post_created",
            related_post: post,
            related_topic: post.topic,
          )

        expect(result).to eq(false)
        expect(user.reload.yak_balance).to eq(0)
      end
    end
  end

  describe ".get_daily_earning_count" do
    it "counts earnings from today only" do
      rule = YakEarningRule.find_by(action_key: "post_created")
      wallet = YakWallet.for_user(user)

      # Create transaction from yesterday
      freeze_time 1.day.ago do
        wallet.add_yaks(rule.amount, "earn", "Earned from: Post Created")
      end

      # Create transaction from today
      wallet.add_yaks(rule.amount, "earn", "Earned from: Post Created")

      count = YakEarningService.get_daily_earning_count(user, "post_created")
      expect(count).to eq(1) # Only today's transaction
    end

    it "returns 0 when user has no wallet" do
      new_user = Fabricate(:user)
      count = YakEarningService.get_daily_earning_count(new_user, "post_created")
      expect(count).to eq(0)
    end
  end

  describe ".can_earn?" do
    it "returns true when all conditions met" do
      result = YakEarningService.can_earn?(user: user, action_key: "post_created")
      expect(result[:can_earn]).to eq(true)
      expect(result[:reason]).to include("Can earn 2 Yaks")
    end

    it "returns false when trust level too low" do
      result = YakEarningService.can_earn?(user: tl0_user, action_key: "post_created")
      expect(result[:can_earn]).to eq(false)
      expect(result[:reason]).to include("Trust level too low")
    end

    it "returns false when daily cap reached" do
      rule = YakEarningRule.find_by(action_key: "post_created")
      wallet = YakWallet.for_user(user)

      # Award up to daily cap
      rule.daily_cap.times { wallet.add_yaks(rule.amount, "earn", "Earned from: Post Created") }

      result = YakEarningService.can_earn?(user: user, action_key: "post_created")
      expect(result[:can_earn]).to eq(false)
      expect(result[:reason]).to include("Daily cap reached")
    end

    it "returns false when rule not found" do
      result = YakEarningService.can_earn?(user: user, action_key: "nonexistent")
      expect(result[:can_earn]).to eq(false)
      expect(result[:reason]).to include("Rule not found")
    end
  end
end
