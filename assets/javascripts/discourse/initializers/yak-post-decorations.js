import { apiInitializer } from "discourse/lib/api";

export default apiInitializer("1.14.0", (api) => {
  api.decorateCookedElement(
    (element, helper) => {
      if (!helper) return;

      const post = helper.getModel();
      if (!post) return;

      const yakFeatures = post.yak_features;
      if (!yakFeatures) return;

      // Try to find article - might not be in DOM yet
      let article = element.closest("article");

      // If not found, wait a tick and try via document query
      if (!article) {
        requestAnimationFrame(() => {
          article = document.querySelector(`article[data-post-id="${post.id}"]`);
          if (!article) return;

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
        });
        return;
      }

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
    },
    { id: "yak-post-decorations" }
  );
});
