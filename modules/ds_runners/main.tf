provider "dotscience" {
  hub_public_url = var.hub_public_url
  hub_admin_password = var.hub_admin_password
}

resource "dotscience_runners" "hub-runners" {
  depends_on = [var.runners_depends_on]
}
