# frozen_string_literal: true

RSpec.describe "Yak earning event hooks" do
  fab!(:user) { Fabricate(:user, trust_level: 1) }

  before do
    SiteSetting.yaks_enabled = true
    SiteSetting.yaks_earning_enabled = true
  end

  it "rewards a new topic only through the topic rule" do
    topic = Fabricate(:topic, user: user)
    first_post =
      Fabricate(
        :post,
        topic: topic,
        user: user,
        post_number: 1,
        raw: "A new topic with enough content to qualify for its configured reward.",
      )
    expect(first_post.is_first_post?).to eq(true)

    expect {
      DiscourseEvent.trigger(:topic_created, topic, {}, user)
      DiscourseEvent.trigger(:post_created, first_post, {}, user)
    }.to change { user.reload.yak_balance }.by(5)

    expect(YakTransaction.pluck(:source)).to contain_exactly("earning_topic_created")
  end

  it "continues to reward regular replies through the post rule" do
    topic = Fabricate(:topic, user: user)
    first_post = Fabricate(:post, topic: topic, user: user, post_number: 1)
    reply =
      Fabricate(
        :post,
        topic: topic,
        user: user,
        post_number: 2,
        raw: "A reply with enough content to qualify for the configured reward.",
      )
    expect(first_post.is_first_post?).to eq(true)
    expect(reply.is_first_post?).to eq(false)

    expect { DiscourseEvent.trigger(:post_created, reply, {}, user) }.to change {
      user.reload.yak_balance
    }.by(2)
  end
end
