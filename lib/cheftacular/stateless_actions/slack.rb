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
    def slack
      notifier = Slack::Notifier.new @config['cheftacular']['slack_webhook'], username: 'Cheftacular'

      notifier.channel = ARGV[2] ? ARGV[2] : '#default'  
      notifier.ping ARGV[1]
    end
  end
end
