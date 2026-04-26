import org.swapiteam.NotificationService

/**
 * Send a Slack notification via incoming webhook.
 *
 * Required keys in config map:
 *   webhook  (String) — incoming webhook URL
 *   message  (String) — message text
 *
 * Optional keys:
 *   color    (String) — 'good', 'warning', or 'danger' (default: 'good')
 */
def call(Map config) {
    def required = ['webhook', 'message']
    required.each { key ->
        if (!config.containsKey(key) || !config[key]) {
            error("notifySlack: required parameter '${key}' is missing or empty")
        }
    }

    def svc = new NotificationService(this, config.webhook as String)
    svc.sendSlack(
        config.message as String,
        (config.color ?: 'good') as String
    )
}
