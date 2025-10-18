import { withPluginApi } from "discourse/lib/plugin-api";
import YakSpendButton from "../components/post-menu/yak-spend-button";

function initializeYakPostActions(api) {
  const currentUser = api.getCurrentUser();
  if (!currentUser) return;

  api.registerValueTransformer("post-menu-buttons", ({ value: dag, context }) => {
    const { post, firstButtonKey } = context;

    // Only show for post author
    if (post.user_id !== currentUser.id) {
      return;
    }

    // Don't show on deleted posts
    if (post.deleted_at) {
      return;
    }

    // Don't show if any yak feature is already active on this post
    if (post.yak_features) {
      return;
    }

    // Don't show on first post if topic has yak features
    if (post.post_number === 1 && post.topic?.yak_features) {
      return;
    }

    dag.add("yak-spend", YakSpendButton, {
      before: firstButtonKey,
    });
  });
}

export default {
  name: "yak-post-actions",
  initialize() {
    withPluginApi("1.14.0", initializeYakPostActions);
  },
};
