export default function () {
  this.route("adminPlugins", { path: "/admin/plugins" }, function () {
    this.route("discourse-yaks", { path: "/discourse-yaks" }, function () {
      this.route("index", { path: "/" });
    });
  });
}
