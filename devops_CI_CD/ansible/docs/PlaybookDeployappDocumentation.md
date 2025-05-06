Gitea Deployment Playbook Documentation
File Location:
/workspace/gitea/devops_CI_CD/ansible/playbooks/deploy/deploy_app.yml

Purpose:
Minimal Ansible playbook for deploying Gitea with only essential components:

Git

Make

Golang

Node.js 18.x

Requirements:

Jenkins-provided variables file:
/tmp/bootstrap_vars.yml

Project configuration file:
/workspace/gitea/devops_CI_CD/ansible/config/vars.yml

Systemd template:
/workspace/gitea/devops_CI_CD/ansible/templates/gitea.service.j2

Playbook Structure:

Package Installation:

Installs core dependencies (git, make, golang, npm)

Configures Node.js 18.x via NodeSource

System Configuration:

Creates required symlink (node -> nodejs)

Clones Gitea repository

Compiles with bindata tags

Service Management:

Deploys systemd service from J2 template

Ensures service is enabled and restarted

File Structure:

/workspace/gitea/devops_CI_CD/ansible/
├── config/
│   └── vars.yml
├── playbooks/
│   └── deploy/
│       └── deploy_app.yml
└── templates/
    └── gitea.service.j2
Execution Command:

bash
ansible-playbook -i inventory /workspace/gitea/devops_CI_CD/ansible/playbooks/deploy/deploy_app.yml
Key Features:

Minimal package set

Proper Node.js 18.x setup

Idempotent operations

CI/CD ready

Uses project-specific variables

Maintains clean separation of concerns