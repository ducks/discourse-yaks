import { apiInitializer } from "discourse/lib/api";

export default apiInitializer("1.14.0", (api) => {
  api.decorateCookedElement(
    (element, helper) => {
      if (!helper) return;

      const post = helper.getModel();
      if (!post) return;

      const yakFeatures = post.yak_features;
      const topic = helper.getModel().topic;
      const topicYakFeatures = topic?.yak_features;

      // Check if this is the first post in a boosted topic
      const isFirstPostInBoostedTopic =
        post.post_number === 1 && topicYakFeatures?.boosted?.enabled;

      if (!yakFeatures && !isFirstPostInBoostedTopic) return;

      // Try to find article - might not be in DOM yet
      let article = element.closest("article");

      // If not found, wait a tick and try via document query
      if (!article) {
        requestAnimationFrame(() => {
          article = document.querySelector(`article[data-post-id="${post.id}"]`);
          if (!article) return;

          // Apply post-level features
          if (yakFeatures) {
            // Apply highlight styling
            if (yakFeatures.highlight?.enabled) {
              article.classList.add("yak-highlighted-post");
              const color = yakFeatures.highlight.color || "gold";
              article.setAttribute("data-yak-color", color);
            }

            // Apply pinned styling
            if (yakFeatures.pinned?.enabled) {
              article.classList.add("yak-pinned-post");
            }

            // Apply boosted styling
            if (yakFeatures.boosted?.enabled) {
              article.classList.add("yak-boosted-post");
            }
          }

          // Apply boosted topic styling to first post
          if (isFirstPostInBoostedTopic) {
            article.classList.add("yak-boosted-topic-post");
            const color = topicYakFeatures.boosted.color || "gold";
            article.classList.add(`yak-color-${color}`);
          }
        });
        return;
      }

      // Apply post-level features
      if (yakFeatures) {
        // Apply highlight styling
        if (yakFeatures.highlight?.enabled) {
          article.classList.add("yak-highlighted-post");
          const color = yakFeatures.highlight.color || "gold";
          article.setAttribute("data-yak-color", color);
        }

        // Apply pinned styling
        if (yakFeatures.pinned?.enabled) {
          article.classList.add("yak-pinned-post");
        }

        // Apply boosted styling
        if (yakFeatures.boosted?.enabled) {
          article.classList.add("yak-boosted-post");
        }
      }

      // Apply boosted topic styling to first post
      if (isFirstPostInBoostedTopic) {
        article.classList.add("yak-boosted-topic-post");
        const color = topicYakFeatures.boosted.color || "gold";
        article.classList.add(`yak-color-${color}`);
      }
    },
    { id: "yak-post-decorations" }
  );
});
