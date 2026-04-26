import org.swapiteam.DockerHelper

/**
 * Build a Docker image and push it to ECR.
 *
 * Required keys in config map:
 *   name        (String) — image name (e.g. 'swapi-app')
 *   tag         (String) — image tag (e.g. 'a1b2c3d')
 *   registry    (String) — ECR registry URL (e.g. '123456789.dkr.ecr.us-east-1.amazonaws.com')
 *   region      (String) — AWS region
 *
 * Optional keys:
 *   dockerfile  (String) — path to Dockerfile (default: 'Dockerfile')
 *   context     (String) — Docker build context (default: '.')
 *   extraTag    (String) — additional tag to apply and push (e.g. branch name)
 */
def call(Map config) {
    def required = ['name', 'tag', 'registry', 'region']
    required.each { key ->
        if (!config.containsKey(key) || !config[key]) {
            error("buildAndPushImage: required parameter '${key}' is missing or empty")
        }
    }

    def helper = new DockerHelper(this, config.registry as String)

    helper.buildImage(
        config.name       as String,
        config.tag        as String,
        (config.dockerfile ?: 'Dockerfile') as String,
        (config.context    ?: '.') as String
    )

    if (config.extraTag) {
        sh "docker tag ${config.name}:${config.tag} ${config.name}:${config.extraTag}"
    }

    helper.ecrLogin(config.region as String)
    helper.pushImage(config.name as String, config.tag as String)

    if (config.extraTag) {
        helper.pushImage(config.name as String, config.extraTag as String)
    }
}
