export default function () {
  this.route("yaks", { path: "/yaks" }, function () {
    this.route("index", { path: "/" });
    this.route("purchase", { path: "/purchase" });
  });

  this.route("adminPlugins", { path: "/admin/plugins" }, function () {
    this.route("discourse-yaks", { path: "/discourse-yaks" }, function () {
      this.route("index", { path: "/" });
    });
  });
}
