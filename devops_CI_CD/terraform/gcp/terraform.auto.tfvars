
network_name          = "gitea-dr-network"
region                = "us-central1"
cidr_block            = "10.10.0.0/16"
gitea_secret_user     = "gitea-user"
gitea_secret_password = "gitea-password"

gitea_vm_name               = "gitea-vm"
machine_type                = "e2-medium"
zone                        = "us-central1-a"
image                       = "ubuntu-os-cloud/ubuntu-2204-lts"
instance_tags               = ["gitea", "web"]
project_id                  = "gitea-dr-457918"
bucket_name                 = "bucket-gitea"
impersonate_service_account = "terraform-dr@gitea-dr-457918.iam.gserviceaccount.com" 