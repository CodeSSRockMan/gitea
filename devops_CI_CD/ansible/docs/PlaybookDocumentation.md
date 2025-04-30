# Terraform Static Analysis Playbook Documentation

## Overview
This Ansible playbook performs static analysis on Terraform files in a Git repository. It follows a bootstrap approach to resolve the \"chicken-and-egg\" problem of needing configuration from a repository before cloning it.

## Workflow

1. **Bootstrap Phase**:
   - Jenkins master sends minimal `bootstrap_vars.yml` to slave
   - Contains only repo URL and branch:
     ```yaml
     repository:
       url: \"https://github.com/CodeSSRockMan/gitea.git\"
       branch: \"SCRM-112\"
     ```

2. **Execution Phase**:
   - Slave clones repository using bootstrap vars
   - Loads full configuration from cloned repo
   - Runs linters on Terraform files
   - Saves results with date-based organization

## Playbook Structure

```yaml
---
- name: Run Terraform static analysis  
  hosts: localhost  
  vars_files:  
    - \"/tmp/bootstrap_vars.yml\"  # From Jenkins master

  tasks:  
    # 1. Install prerequisites  
    - name: Install Git  
      package:  
        name: git  
        state: present  

    - name: Install Docker  
      package:  
        name: docker  
        state: present  

    # 2. Clone repo  
    - name: Clone repository  
      git:  
        repo: \"{{ repository.url }}\"  
        dest: \"/workspace/gitea\"  
        version: \"{{ repository.branch }}\"  
        force: yes  

    # 3. Load project config  
    - name: Load project variables  
      include_vars:  
        file: \"/workspace/gitea/devops_CI_CD/ansible/config/vars.yml\"  

    # 4. Find and lint files  
    - name: Get Terraform files  
      find:  
        paths: \"/workspace/gitea/devops_CI_CD/terraform\"  
        patterns: \"*.tf\"  
        recurse: yes  
      register: tf_files  

    - name: Lint Terraform files  
      docker_container:  
        name: \"tflint_{{ item | basename }}\"  
        image: \"{{ terraform.linter.container }}\"  
        command: \"{{ terraform.linter.args }} /code/{{ item | basename }}\"  
        volumes:  
          - \"/workspace/gitea/devops_CI_CD/terraform:/code\"  
        auto_remove: yes  
      loop: \"{{ tf_files.files | map(attribute='path') | list }}\"  
      register: lint_results  

    # 5. Save logs  
    - name: Write logs  
      copy:  
        content: \"{{ lint_results.results | to_json }}\"  
        dest: \"/workspace/gitea/devops_CI_CD/logs/{{ ansible_date_time.date }}/tflint.json\"  

    # 6. Completion status  
    - name: Exit with status  
      command: exit 0  
      changed_when: false  

      