# swapi-shared-lib — Jenkins Shared Library

A reusable Jenkins shared library for the SWAPI CI/CD pipeline.

## Registration in Jenkins

**Manage Jenkins > System > Global Pipeline Libraries > Add**

| Field              | Value             |
|--------------------|-------------------|
| Name               | `swapi-shared-lib` |
| Default version    | `main`            |
| Load implicitly    | disabled          |
| Retrieval method   | Modern SCM / GitHub |

Use in a Jenkinsfile with:
```groovy
@Library('swapi-shared-lib') _
```

---

## Global Variables (`vars/`)

### `notifySlack`
Send a Slack message via an incoming webhook.

**Required parameters:**
- `webhook` — incoming webhook URL
- `message` — message text

**Optional parameters:**
- `color` — `'good'` (green), `'warning'` (yellow), or `'danger'` (red). Default: `'good'`

**Usage:**
```groovy
notifySlack([
    webhook: env.SLACK_WEBHOOK,
    message: "Build ${env.BUILD_NUMBER} succeeded!",
    color  : 'good'
])
```

---

### `buildAndPushImage`
Build a Docker image and push both a SHA tag and a branch tag to AWS ECR.

**Required parameters:**
- `name` — image name (e.g. `'swapi-app'`)
- `tag` — primary tag (e.g. short git SHA)
- `registry` — ECR registry URL
- `region` — AWS region

**Optional parameters:**
- `dockerfile` — path to Dockerfile (default: `'Dockerfile'`)
- `context` — Docker build context (default: `'.'`)
- `extraTag` — additional tag (e.g. branch name)

**Usage:**
```groovy
buildAndPushImage([
    name      : 'swapi-app',
    tag       : env.GIT_COMMIT[0..6],
    extraTag  : env.BRANCH_NAME,
    registry  : "${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com",
    region    : 'us-east-1',
    dockerfile: 'assignment-4/Dockerfile',
    context   : 'assignment-4/'
])
```

---

### `runSonarScan`
Run the SonarQube scanner and block until the Quality Gate resolves.

**Required parameters:**
- `projectKey` — SonarQube project key
- `sources` — source path(s)
- `serverName` — server name as registered in Jenkins

**Optional parameters:**
- `coverageReport` — path to XML coverage report
- `exclusions` — glob patterns to exclude
- `timeoutMinutes` — Quality Gate wait timeout (default: `5`)

**Usage:**
```groovy
runSonarScan([
    projectKey    : 'swapi-app',
    sources       : '.',
    serverName    : 'SonarQube',
    coverageReport: 'coverage.xml',
    exclusions    : 'tests/**,*.cfg'
])
```

---

## Groovy Classes (`src/org/swapiteam/`)

### `NotificationService`
Wraps Slack webhook calls and Jenkins `emailext`.

```groovy
import org.swapiteam.NotificationService
def svc = new NotificationService(this, env.SLACK_WEBHOOK)
svc.sendSlack('Build passed', 'good')
svc.sendEmail('team@example.com', 'Build passed', 'Details here.')
```

### `DockerHelper`
Wraps `docker build`, `docker tag`, `docker push`, and ECR login.

```groovy
import org.swapiteam.DockerHelper
def docker = new DockerHelper(this, env.ECR_REGISTRY)
docker.ecrLogin('us-east-1')
docker.buildImage('swapi-app', 'abc1234')
docker.pushImage('swapi-app', 'abc1234')
```
