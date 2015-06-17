class Cheftacular
  class StatelessActionDocumentation
    def slack
      @config['documentation']['stateless_action'] <<  [
        "`cft slack \"MESSAGE\" [CHANNEL]` will attempt to post the message to the webhook set in your cheftacular.yml. " +
        "Slack posts to your default channel by default but if the CHANNEL argument is supplied the message will post there.",

        [
          "    1. NOTE: To prevent confusing spam from many possible sources, the username posted to slack will always be " +
          "*Cheftacular*. This can be overloaded in the StatelessAction method \"slack\" but this is not recommended.",

          "    2. Remember, if you have auditing turned on in your cheftacular.yml, you can track who sends what to slack."
        ]
      ]
    end
  end

  class StatelessAction
    def slack message='', channel=''
      @slack_notifier ||= Slack::Notifier.new @config['cheftacular']['slack']['webhook'], username: 'Cheftacular'

      message = ARGV[1] if message.blank?
      channel = ARGV[2] if channel.blank?

      @slack_notifier.channel = channel.nil? ? @config['cheftacular']['slack']['default_channel'] : channel
      @slack_notifier.ping message
    end
  end
end
