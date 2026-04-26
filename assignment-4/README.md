# Assignment 4 — CI/CD Pipelines with Jenkins and Groovy

## Team Members

| Roll Number | Name       | Contribution                         |
|-------------|------------|--------------------------------------|
| 22F-3722    | Member 1   | Tasks 1, 2, 3                        |
| 22F-3708    | Member 2   | Tasks 4, 5, 6, 7                     |

## Repository Structure

```
assignment-4/
├── app/                    # Flask application (Task 2)
│   ├── app.py              # Main app — /health, /api/planets, /api/people
│   ├── models.py           # PlanetService, PersonService, domain models
│   ├── requirements.txt
│   ├── setup.cfg           # pytest + coverage config
│   └── tests/
│       ├── unit/           # 13 unit tests (TestPlanetModel, TestPersonModel, etc.)
│       └── integration/    # 12 integration tests (REST endpoints)
├── jenkins/                # Task 1 setup
│   ├── plugins.txt         # All installed plugins
│   ├── setup.md            # Step-by-step setup guide
│   └── terraform/          # EC2 for controller + agent
├── pipelines/              # Jenkinsfiles
│   ├── Jenkinsfile.infra   # Task 6 — parameterized Terraform pipeline
│   ├── Jenkinsfile.rollback# Task 7 — blue-green rollback
│   └── blue-green-deploy.sh# Task 7 — deployment script
├── terraform/              # Task 7 — blue-green + ECR + SonarQube
│   ├── main.tf
│   ├── modules/blue-green/
│   ├── modules/ecr/
│   └── modules/sonarqube/
├── shared-library/         # Task 3 — Groovy shared library source
│   ├── vars/               # notifySlack, buildAndPushImage, runSonarScan
│   └── src/org/swapiteam/ # NotificationService, DockerHelper
├── observability/          # Prometheus + Grafana
│   ├── docker-compose.yml
│   ├── prometheus.yml
│   └── runbook.md
├── Dockerfile              # Task 5 — multi-stage, non-root user
├── Jenkinsfile             # Task 2 — main declarative pipeline
├── sonar-project.properties# Task 4 — SonarQube project config
└── .trivyignore            # Task 5 — CVE ignore list with justifications
```

## Prerequisites

- AWS CLI configured with credentials
- Terraform >= 1.5
- Docker
- Python 3.12+
- Jenkins 2.x (LTS) with plugins listed in `jenkins/plugins.txt`

## Quick Start

### 1 — Provision Jenkins Infrastructure

```bash
cd assignment-4/jenkins/terraform
cp terraform.tfvars.example terraform.tfvars   # fill in VPC/subnet IDs
terraform init && terraform apply
```

Access Jenkins at `http://<controller-public-ip>:8080`

### 2 — Provision App Infrastructure (ECR + Blue-Green + SonarQube)

```bash
cd assignment-4/terraform
cp terraform.tfvars.example terraform.tfvars   # fill in SG IDs etc.
terraform init && terraform apply
```

### 3 — Run the App Pipeline

In Jenkins: trigger the `swapi-app` Multibranch Pipeline job on the `main` branch.  
Stages: Checkout → Build → Static Analysis → Test (parallel) → Package → Container Build → Security Scan → Push to ECR → Deploy-Production

### 4 — Run the Terraform (infra-pipeline) Pipeline

In Jenkins: run `infra-pipeline` with `ACTION=plan` first, then `ACTION=apply`.

### 5 — Start Observability Stack

```bash
cd assignment-4/observability
docker-compose up -d
# Grafana: http://localhost:3000  (admin/admin)
# Prometheus: http://localhost:9090
```

## Running Tests Locally

```bash
cd assignment-4/app
python3 -m venv .venv && . .venv/bin/activate
pip install -r requirements.txt
pytest tests/unit -v                          # unit tests only
pytest tests/integration -v                   # integration tests only
pytest --cov=. --cov-report=html              # all tests with coverage
```

## Teardown

```bash
# App infrastructure
cd assignment-4/terraform && terraform destroy

# Jenkins infrastructure
cd assignment-4/jenkins/terraform && terraform destroy

# Observability
cd assignment-4/observability && docker-compose down -v
```

## Shared Library

The Groovy shared library lives in a separate GitHub repository: **jenkins-shared-library**.  
Register it in Jenkins under *Manage Jenkins > System > Global Pipeline Libraries* with name `swapi-shared-lib`.  
See `shared-library/README.md` for full API documentation.

## Notes

- No secrets are committed to this repository. All credentials are stored in Jenkins Credential Manager and injected via `credentials()`.
- The `terraform.tfvars` files contain only non-sensitive placeholder values.
- `.terraform/` directories and `*.tfstate` files are excluded via `.gitignore`.
