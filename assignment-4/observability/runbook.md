# Observability Runbook

## Stack

| Service    | Port | URL                            |
|------------|------|--------------------------------|
| Prometheus | 9090 | http://\<host\>:9090           |
| Grafana    | 3000 | http://\<host\>:3000 (admin/admin) |

## Start

```bash
cd assignment-4/observability
docker-compose up -d
```


## Grafana Setup

1. Log in at `http://<host>:3000` with `admin` / `admin` (change on first login).
2. Add Prometheus data source: `http://prometheus:9090`.
3. Import Jenkins dashboard: **Dashboards > Import > ID 9964** (Jenkins performance).

## Key Metrics to Watch

| Metric                                  | Description                          |
|-----------------------------------------|--------------------------------------|
| `jenkins_builds_duration_milliseconds`  | Build duration histogram             |
| `jenkins_builds_failed_builds_total`    | Total failed builds counter          |
| `jenkins_builds_success_build_count`    | Total successful builds              |
| `jenkins_executor_count`                | Number of executors available        |
| `jenkins_queue_size_value`              | Jobs waiting in the build queue      |

## Alerts (Prometheus rules — add to prometheus.yml)

```yaml
groups:
  - name: jenkins_alerts
    rules:
      - alert: BuildQueueHighWatermark
        expr: jenkins_queue_size_value > 5
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Jenkins build queue exceeds 5 items for 5 minutes"

      - alert: HighBuildFailureRate
        expr: rate(jenkins_builds_failed_builds_total[10m]) > 0.5
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "More than 50% of builds are failing"
```

## Teardown

```bash
docker-compose down -v
```
