import { withPluginApi } from "discourse/lib/plugin-api";
import { i18n } from "discourse-i18n";

export default {
  name: "yak-user-menu",

  initialize(container) {
    withPluginApi("1.14.0", (api) => {
      const siteSettings = container.lookup("service:site-settings");
      if (!siteSettings.yaks_enabled) {
        return;
      }

      const currentUser = api.getCurrentUser();
      if (!currentUser) {
        return;
      }

      // Subscribe to balance updates via MessageBus
      const messageBus = container.lookup("service:message-bus");
      messageBus.subscribe(`/yak-balance/${currentUser.id}`, (data) => {
        currentUser.set("yak_balance", data.balance);
      });

      // Add balance display to user menu profile tab
      api.addQuickAccessProfileItem({
        icon: "dollar-sign",
        href: "/yaks",
        get content() {
          return i18n("yaks.user_menu.balance", {
            count: currentUser.yak_balance || 0
          });
        },
      });
    });
  },
};
