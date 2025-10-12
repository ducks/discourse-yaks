import { withPluginApi } from "discourse/lib/plugin-api";
import { getOwner } from "@ember/application";
import SpendYaksModal from "../components/modal/spend-yaks";

/**
 * @file Adds Yak spending button to topic footer
 */

/**
 * Initializes Yak topic actions
 * @param {object} api - Discourse plugin API
 */
function initializeYakTopicActions(api) {
  const currentUser = api.getCurrentUser();
  if (!currentUser) return;

  api.registerTopicFooterButton({
    id: "yak-spend-topic",
    icon: "gift",
    priority: 250,
    label: "yaks.post_action.spend",
    title: "yaks.post_action.spend_yaks",
    action() {
      const topic = this.topic;

      // Only show for topic author
      if (topic.user_id !== currentUser.id) {
        return;
      }

      // Don't show on closed topics
      if (topic.closed) {
        return;
      }

      // Get modal service from owner
      const modal = getOwner(this).lookup("service:modal");

      // Open the spend modal with topic context
      modal.show(SpendYaksModal, {
        model: {
          topic: topic,
        },
      });
    },
    dropdown() {
      return this.site.mobileView;
    },
    classNames: ["yak-spend-topic"],
    dependentKeys: ["topic.user_id", "topic.closed"],
    displayed() {
      const topic = this.topic;

      // Only show for topic author
      if (topic.user_id !== currentUser.id) {
        return false;
      }

      // Don't show on closed topics
      if (topic.closed) {
        return false;
      }

      return true;
    },
  });
}

export default {
  name: "yak-topic-actions",
  initialize() {
    withPluginApi("1.14.0", initializeYakTopicActions);
  },
};
