/**
 * Run SonarQube scanner and wait for Quality Gate result.
 *
 * Required keys in config map:
 *   projectKey   (String) — SonarQube project key
 *   sources      (String) — comma-separated source paths (e.g. '.')
 *   serverName   (String) — name registered in Jenkins SonarQube config
 *
 * Optional keys:
 *   coverageReport  (String) — path to XML coverage report
 *   exclusions      (String) — comma-separated glob patterns to exclude
 *   timeoutMinutes  (int)    — Quality Gate timeout (default: 5)
 */
def call(Map config) {
    def required = ['projectKey', 'sources', 'serverName']
    required.each { key ->
        if (!config.containsKey(key) || !config[key]) {
            error("runSonarScan: required parameter '${key}' is missing or empty")
        }
    }

    withSonarQubeEnv(config.serverName as String) {
        def args = [
            "-Dsonar.projectKey=${config.projectKey}",
            "-Dsonar.sources=${config.sources}",
        ]
        if (config.coverageReport) {
            args << "-Dsonar.python.coverage.reportPaths=${config.coverageReport}"
        }
        if (config.exclusions) {
            args << "-Dsonar.exclusions=${config.exclusions}"
        }
        sh "sonar-scanner ${args.join(' ')}"
    }

    int timeoutMins = (config.timeoutMinutes ?: 5) as int
    timeout(time: timeoutMins, unit: 'MINUTES') {
        def qg = waitForQualityGate()
        if (qg.status != 'OK') {
            error("SonarQube Quality Gate failed: status=${qg.status}")
        }
    }
}
