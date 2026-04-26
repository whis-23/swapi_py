package org.swapiteam

class DockerHelper implements Serializable {
    private final def script
    private final String registry

    DockerHelper(script, String registry = '') {
        this.script = script
        this.registry = registry
    }

    void buildImage(String name, String tag, String dockerfile = 'Dockerfile', String context = '.') {
        if (!name) { script.error('DockerHelper.buildImage: name is required') }
        if (!tag)  { script.error('DockerHelper.buildImage: tag is required') }
        script.sh(
            label : "Build Docker image ${name}:${tag}",
            script: "docker build -t ${name}:${tag} -f ${dockerfile} ${context}"
        )
    }

    void pushImage(String name, String tag) {
        if (!name) { script.error('DockerHelper.pushImage: name is required') }
        if (!tag)  { script.error('DockerHelper.pushImage: tag is required') }
        String fullName = registry ? "${registry}/${name}:${tag}" : "${name}:${tag}"
        if (registry) {
            script.sh(
                label : "Tag image for registry",
                script: "docker tag ${name}:${tag} ${fullName}"
            )
        }
        script.sh(
            label : "Push ${fullName}",
            script: "docker push ${fullName}"
        )
    }

    void ecrLogin(String region) {
        if (!registry) { script.error('DockerHelper.ecrLogin: registry must be set') }
        script.sh(
            label : 'ECR login via IAM role',
            script: """
                aws ecr get-login-password --region ${region} | \
                    docker login --username AWS --password-stdin ${registry}
            """
        )
    }
}
