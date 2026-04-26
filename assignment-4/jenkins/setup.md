# Jenkins Controller and Agent Setup

## Overview

| Component        | Instance Type | Subnet  | Port  |
|------------------|---------------|---------|-------|
| Jenkins Controller | t3.medium   | Public  | 8080  |
| Jenkins Agent    | t3.small      | Private | 22    |
| SonarQube        | t3.small      | Public  | 9000  |

> Note: Jenkins runs on port **8080** (default Jenkins LTS port).

---

## Step 1 — Provision Infrastructure via Terraform

```bash
cd assignment-4/jenkins/terraform
terraform init
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

This creates:
- `jenkins-controller` EC2 in the public subnet with a user_data script that installs Jenkins LTS, Java 17, Git, Docker, AWS CLI, and Terraform.
- `jenkins-agent` EC2 in the private subnet with Java 17, Git, and Docker pre-installed.

---

## Step 2 — Complete the Jenkins Setup Wizard

1. SSH into the controller: `ssh -i <key.pem> ubuntu@<controller-public-ip>`
2. Retrieve the initial admin password: `sudo cat /var/lib/jenkins/secrets/initialAdminPassword`
3. Open `http://<controller-public-ip>:8080` in a browser.
4. Select **Install suggested plugins**.
5. Install additional required plugins from **Manage Jenkins > Plugins > Available**:
   - Pipeline, Git, GitHub Branch Source, Docker Pipeline
   - Credentials Binding, Pipeline Utility Steps, SonarQube Scanner, Blue Ocean
6. Create an admin user (do **not** keep the initial password).

---

## Step 3 — Configure the Build Agent

1. In Jenkins: **Manage Jenkins > Nodes > New Node**
   - Name: `linux-agent`
   - Type: Permanent Agent
   - Remote root directory: `/home/ubuntu/jenkins`
   - Label: `linux-agent`
   - Launch method: **Launch agents via SSH**
   - Host: `<agent-private-ip>`
   - Credentials: Add SSH private key credential (ID: `jenkins-agent-ssh-key`)
   - Host Key Verification: Non-verifying (or add host key manually)
2. Save and verify the agent comes **Online** in the Nodes page.

---

## Step 4 — Create Jenkins Credentials

Navigate to **Manage Jenkins > Credentials > System > Global credentials (unrestricted)**:

| Credential ID         | Kind                        | Description                     |
|-----------------------|-----------------------------|---------------------------------|
| `aws-access-key-id`   | Secret text                 | AWS Access Key ID               |
| `aws-secret-key`      | Secret text                 | AWS Secret Access Key           |
| `github-pat`          | Username with password      | GitHub Personal Access Token    |
| `sonarqube-token`     | Secret text                 | SonarQube project token         |
| `slack-webhook-url`   | Secret text                 | Slack incoming webhook URL      |
| `aws-account-id`      | Secret text                 | AWS Account ID (12-digit)       |
| `jenkins-agent-ssh-key` | SSH Username with private key | Agent SSH key               |

**No secret value is stored in any committed file.**

---

## Step 5 — Configure GitHub Integration

1. **Manage Jenkins > System**: under GitHub, add a GitHub Server entry.
2. Add credentials: select `github-pat`.
3. Click **Test connection** — should return your GitHub username.
4. In your GitHub repo: **Settings > Webhooks > Add webhook**
   - Payload URL: `http://<controller-ip>:8080/github-webhook/`
   - Content type: `application/json`
   - Events: Push + Pull request

---

## Step 6 — Create the Multibranch Pipeline

1. **New Item > Multibranch Pipeline** — name: `swapi-app`
2. Branch Sources: add GitHub, select credential `github-pat`, enter repo URL.
3. Build Configuration: by Jenkinsfile — Script Path: `assignment-4/Jenkinsfile`
4. Scan Multibranch Pipeline Triggers: periodically if not indexed — 1 minute.
5. Save. Jenkins will scan and create branch jobs automatically.

---

## Step 7 — Register Shared Library

1. **Manage Jenkins > System > Global Pipeline Libraries > Add**
   - Name: `swapi-shared-lib`
   - Default version: `main`
   - Retrieval method: Modern SCM > GitHub
   - Repository URL: `https://github.com/<your-org>/jenkins-shared-library`
   - Credentials: `github-pat`
2. Keep **Load implicitly** disabled — pipelines use `@Library('swapi-shared-lib') _`.

---

## Step 8 — Register SonarQube Server

1. **Manage Jenkins > System > SonarQube servers > Add**
   - Name: `SonarQube`
   - Server URL: `http://<sonarqube-ec2-private-ip>:9000`
   - Server authentication token: select `sonarqube-token`
2. In SonarQube UI: **Administration > Configuration > Webhooks > Create**
   - URL: `http://<controller-ip>:8080/sonarqube-webhook/`
