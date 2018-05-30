Discourse::Application.routes.append {
  scope "/admin/flexible-rate-limits", constraints: AdminConstraint.new {
    get "/"       => "admin/flexible_rate_limits#index"
    get "save"    => "admin/flexible_rate_limits#save"
  }
}
