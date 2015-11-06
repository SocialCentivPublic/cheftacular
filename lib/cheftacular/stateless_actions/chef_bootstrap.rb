
class Cheftacular
  class StatelessActionDocumentation
    def chef_bootstrap
      @config['documentation']['stateless_action'][__method__] ||= {}
      @config['documentation']['stateless_action'][__method__]['long_description'] = [
        "`cft chef_bootstrap ADDRESS NODE_NAME` allows you to register a node in the chef system, " + 
        "remove any lingering data that may be associated with it and update the node's runlist if it has an entry in nodes_dir for its NODE_NAME.",

        [
          "    1. This command is part of the `cft full_bootstrap` command"
        ]
      ]

      @config['documentation']['stateless_action'][__method__]['short_description'] = 'Bootstraps basic chef properties on the target server'
    end
  end

  class StatelessAction
    def chef_bootstrap out=[]
      raise "This action can only be performed if the mode is set to devops" if !@config['helper'].running_in_mode?('devops') && !@options['in_scaling']
        
      @options['address']   = ARGV[1] unless @options['address']
      @options['node_name'] = ARGV[2] unless @options['node_name']

      #@config['stateless_action'].remove_client #just in case

      if @config['cheftacular']['chef_version'].to_i >= 12
        puts("Starting chef-client installation...") unless @options['quiet']

        commands = [
          "curl -L https://www.opscode.com/chef/install.sh > ~/chef-install.sh",
          "#{ @config['helper'].sudo(@options['address']) } bash /home/deploy/chef-install.sh",
          "rm ~/chef-install.sh"
        ]

        commands.each do |command|
          out << `ssh -t -oStrictHostKeyChecking=no #{ @config['cheftacular']['deploy_user'] }@#{ @options['address'] } "#{ command }"`

          puts(out.last) unless @options['quiet'] || @options['in_scaling']
        end
      end

      puts("Starting chef bootstrap...") unless @options['quiet']

      out << `#{ @config['helper'].knife_bootstrap_command }`

      puts(out.last) unless @options['quiet'] || @options['in_scaling']

      puts("Sending up data_bag_key file...") unless @options['quiet']

      out << `scp -oStrictHostKeyChecking=no #{ @config['locs']['chef'] }/#{ @config['cheftacular']['data_bag_key_file'] } #{ @config['cheftacular']['deploy_user'] }@#{ @options['address'] }:/home/#{ @config['cheftacular']['deploy_user'] }`

      puts("Moving key file to chef directory on server...") unless @options['quiet']

      out << `ssh -t -oStrictHostKeyChecking=no #{ @config['cheftacular']['deploy_user'] }@#{ @options['address'] } "#{ @config['helper'].sudo(@options['address']) } mv -f /home/#{ @config['cheftacular']['deploy_user'] }/#{  @config['cheftacular']['data_bag_key_file'] } /etc/chef"`

      @options['force_yes'] = true # have the upload_nodes grab the new nodes

      @config['stateless_action'].upload_nodes(true)
    end
  end
end
