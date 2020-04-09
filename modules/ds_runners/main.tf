provider "dotscience" {
  hub_public_url = var.hub_public_url
  hub_admin_password = var.hub_admin_password
  version = "~> 0.0.1"
}

resource "dotscience_runners" "hub-runners" {
  depends_on = [var.runners_depends_on]
}
