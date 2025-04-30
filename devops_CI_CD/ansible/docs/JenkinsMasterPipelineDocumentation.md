```markdown
# Static Analysis Pipeline Documentation

## Pipeline Overview
Jenkins pipeline for multi-branch static analysis using ephemeral Docker agents

## Requirements
- Jenkins with Docker pipeline plugin
- Docker daemon accessible to agents
- Ansible installed on Jenkins controller

## Pipeline Parameters
| Parameter | Type | Choices | Description |
|-----------|------|---------|-------------|
| `EXECUTION_MODE` | choice | `sequential`, `parallel`, `single` | Analysis execution strategy |
| `TARGET_LINTER` | choice | `terraform`, `ansible`, `docker`, `jenkins` | Required when mode=`single` |
| `BRANCH_NAME` | choice | `develop`, `infra-aws`, `infra-gcp`, `monitoring` | Target branch for analysis |

## Pipeline Implementation
```groovy
pipeline {
    agent none
    
    parameters {
        choice(
            name: 'EXECUTION_MODE',
            choices: ['sequential','parallel','single'],
            description: 'Execution strategy for linters'
        )
        choice(
            name: 'TARGET_LINTER',
            choices: ['terraform','ansible','docker','jenkins'],
            description: 'Required when mode=single'
        )
        choice(
            name: 'BRANCH_NAME',
            choices: ['develop','infra-aws','infra-gcp','monitoring'],
            description: 'Branch to analyze'
        )
    }
    
    options {
        timeout(time: 30, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }
    
    environment {
        WORKSPACE_PATH = '/workspace/gitea'
        CONFIG_FILE = 'devops_CI_CD/ansible/config/vars.yml'
        PLAYBOOK = 'devops_CI_CD/ansible/playbooks/static_analysis/master_lint.yml'
    }
    
    stages {
        stage('Static Analysis') {
            agent {
                docker {
                    image 'docker:latest'
                    args '--privileged -v /var/run/docker.sock:/var/run/docker.sock -v /workspace/gitea:/workspace/gitea'
                    reuseNode false
                }
            }
            steps {
                ansiblePlaybook(
                    playbook: \"${PLAYBOOK}\",
                    inventory: 'localhost,',
                    extras: \"\"\"
                        -e '{
                            \\\"execution_mode\\\": \\\"${params.EXECUTION_MODE}\\\",
                            \\\"target_linter\\\": \\\"${params.TARGET_LINTER}\\\",
                            \\\"branch_name\\\": \\\"${params.BRANCH_NAME}\\\"
                        }' -e @${CONFIG_FILE}
                    \"\"\",
                    colorized: true
                )
            }
            post {
                always {
                    archiveArtifacts artifacts: \"devops_CI_CD/logs/${params.BRANCH_NAME}/**/*.json\"
                }
            }
        }
    }
    
    post {
        failure {
            script {
                def recipient = params.BRANCH_NAME == 'develop' ? 'devops@example.com' : 
                              \"${params.BRANCH_NAME}-team@example.com\"
                emailext (
                    subject: \"FAILED: Static Analysis for ${params.BRANCH_NAME}\",
                    body: \"\"\"Check console output at ${env.BUILD_URL}console\"\"\",
                    to: recipient
                )
            }
        }
        cleanup {
            script {
                sh '''
                    docker ps -aq --filter \"name=static_analysis_*\" | xargs --no-run-if-empty docker rm -f || true
                '''
            }
        }
    }
}
```

## Directory Structure
```
/workspace/gitea/
└── devops_CI_CD/
    ├── ansible/
    │   ├── playbooks/
    │   │   └── static_analysis/
    │   │       ├── master_lint.yml
    │   │       ├── terraform_lint.yml
    │   │       ├── ansible_lint.yml
    │   │       ├── docker_lint.yml
    │   │       └── jenkinsfile_lint.yml
    │   └── config/
    │       └── vars.yml
    └── logs/
        └── <branch_name>/
            ├── terraform.json
            ├── ansible.json
            ├── docker.json
            └── jenkinsfile.json
```

## Webhook Configuration
```bash
# Sample webhook trigger
curl -X POST \\
  -H \"Content-Type: application/json\" \\
  -d '{\"BRANCH_NAME\":\"infra-aws\",\"EXECUTION_MODE\":\"parallel\"}' \\
  http://jenkins/generic-webhook-trigger/invoke?token=STATIC_ANALYSIS
```

## Troubleshooting
1. **Container failures**:
   ```bash
   # Check Docker logs:
   journalctl -u docker | grep static_analysis
   ```
   
2. **Permission issues**:
   ```bash
   chmod 777 /var/run/docker.sock
   ```

3. **Missing logs**:
   ```bash
   ls -la /workspace/gitea/devops_CI_CD/logs/${BRANCH_NAME}
   ```
```