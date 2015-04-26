class Cheftacular
  class StatelessActionDocumentation
    def slack
      @config['documentation']['stateless_action'] <<  [
        "`cft slack \"MESSAGE\" [CHANNEL]` will attempt to post the message to the webhook set in your cheftacular.yml. " +
        "Slack posts to your default channel by default but if the CHANNEL argument is supplied the message will post there.",
      ]
    end
  end

  class StatelessAction
    def slack
      notifier = Slack::Notifier.new @config['cheftacular']['slack_webhook'], username: 'Cheftacular'

      notifier.channel = '#default' unless ARGV[2]  
      notifier.ping ARGV[1]
    end
  end
end
