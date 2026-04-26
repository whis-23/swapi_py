package org.swapiteam

class NotificationService implements Serializable {
    private final def script
    private final String defaultWebhook

    NotificationService(script, String defaultWebhook = '') {
        this.script = script
        this.defaultWebhook = defaultWebhook
    }

    void sendSlack(String message, String color = 'good', String webhook = '') {
        String url = webhook ?: defaultWebhook
        if (!url) {
            script.error('NotificationService.sendSlack: no webhook URL provided')
        }
        String payload = groovy.json.JsonOutput.toJson([
            text        : message,
            attachments : [[color: color, text: message]]
        ])
        script.sh(
            label : 'Send Slack notification',
            script: """
                curl -s -X POST -H 'Content-type: application/json' \
                     --data '${payload}' '${url}'
            """
        )
    }

    void sendEmail(String to, String subject, String body) {
        if (!to) {
            script.error('NotificationService.sendEmail: recipient address is required')
        }
        script.emailext(
            to      : to,
            subject : subject,
            body    : body
        )
    }
}
