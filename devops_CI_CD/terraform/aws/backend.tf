terraform {
  backend "remote" {
    organization = "SoftServe_Devops"

    workspaces {
      name = "terraform-infra"
    }
  }
}
