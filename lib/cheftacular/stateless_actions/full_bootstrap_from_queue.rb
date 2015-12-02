
class Cheftacular
  class StatelessActionDocumentation
    def full_bootstrap_from_queue
      @config['documentation']['stateless_action'][__method__] ||= {}
      @config['documentation']['stateless_action'][__method__]['long_description'] = [
        "`cft full_bootstrap_from_queue` This command performs both " +
        "#{ @config['cheftacular']['preferred_cloud_os'] }_bootstrap and chef_bootstrap.",

        [
          "    1. This command is run by `cft cloud_bootstrap` and should not be run on its own."
        ]
      ]

      @config['documentation']['stateless_action'][__method__]['short_description'] = '[Not Directly Callable]'
    end
  end

  class StatelessAction
    def full_bootstrap_from_queue options_to_sync=['node_name', 'address', 'client_pass']
      raise "This action can only be performed if the mode is set to devops" if !@config['helper'].running_in_mode?('devops') && !@options['in_scaling']

      case @config['cheftacular']['preferred_cloud_os']
      when 'ubuntu' || 'debian' then @config['stateless_action'].ubuntu_bootstrap_from_queue
      else                           @config['stateless_action'].instance_eval("#{ @config['cheftacular']['preferred_cloud_os'] }_bootstrap_from_queue")
      end

      @config['initializer'].initialize_passwords @options['env'] #reset the passwords var to contain the new deploy pass set in ubuntu_bootstrap

      @config['stateless_action'].chef_bootstrap_from_queue
    end
  end
end
