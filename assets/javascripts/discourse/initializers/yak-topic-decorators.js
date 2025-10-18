import { withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "yak-topic-decorators",
  initialize() {
    withPluginApi("1.14", (api) => {
      api.registerValueTransformer("topic-list-item-class", ({ value, context }) => {
        const topic = context?.topic;
        if (topic?.yak_features?.boosted?.enabled) {
          value.push("yak-boosted-topic");
          const color = topic.yak_features.boosted.color || "gold";
          value.push(`yak-color-${color}`);
        }
        return value;
      });
    });
  },
};
