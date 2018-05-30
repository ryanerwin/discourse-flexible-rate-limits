export default {
  resource: "admin",
  map() {
    this.route("flexibleRateLimits", { path: "flexible-rate-limits" });
  }
};