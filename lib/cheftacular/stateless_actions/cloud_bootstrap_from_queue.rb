
class Cheftacular
  class StatelessActionDocumentation
    def cloud_bootstrap_from_queue
      @config['documentation']['stateless_action'][__method__] ||= {}
      @config['documentation']['stateless_action'][__method__]['long_description'] = [
        "`cft cloud_bootstrap_from_queue` uses a cloud api to " +
        "create several servers. It is a wrapper around the cloud_bootstrap command that tries to queue server creation.",

        [
          "    1. This command cannot be called directly and can only be utilized from `cft environment boot`",
        ]
      ]

      @config['documentation']['stateless_action'][__method__]['short_description'] = '[Not Directly Callable]'
    end
  end

  class StatelessAction
    def cloud_bootstrap_from_queue
      raise "This action is not meant to be called directly!" unless @options['in_scaling']

      @config['in_server_creation_queue'] = true

      @config['server_creation_queue'].each do |server_hash|
        puts("Preparing to boot server #{ server_hash['node_name'] } for #{ @options['env'] }!") unless @options['quiet']

        puts("Creating server #{ server_hash['node_name'] } with arguments:") unless @options['quiet']
        ap(server_hash.except('node_name'))                                   unless @options['quiet']

        @config['stateless_action'].cloud_bootstrap(server_hash)
      end

      @config['stateless_action'].full_bootstrap_from_queue
    end
  end
end
