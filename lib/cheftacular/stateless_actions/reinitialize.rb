#This command is meant to be run on servers that are not attached the the current chef server
class Cheftacular
  class StatelessActionDocumentation
    def reinitialize
      @config['documentation']['action'] <<  [
        "`cft reinitialize IP_ADDRESS NODE_NAME` will reconnect a server previously managed by chef to a new chef server. " +
        "The node name MUST MATCH THE NODE'S ORIGINAL NODE NAME for the roles to be setup correctly."
      ]
    end
  end

  class StatelessAction
    def reinitialize out=[]
      raise "This action can only be performed if the mode is set to devops" unless @config['helper'].running_in_mode?('devops')

      @options['address']   = ARGV[1] unless @options['address']
      @options['node_name'] = ARGV[2] unless @options['node_name']

      puts("Sending up validator file...") unless @options['quiet']

      chef_user = @config['cheftacular']['deploy_user']

      out << `scp -oStrictHostKeyChecking=no #{ @config['locs']['chef'] }/chef-validator.pem #{ chef_user }@#{ @options['address'] }:/home/#{ chef_user }`

      puts("Moving validator file to chef directory on server...") unless @options['quiet']

      out << `ssh -t -oStrictHostKeyChecking=no #{ chef_user }@#{ @options['address'] } "#{ sudo(@options['address']) } mv -f /home/#{ chef_user }/chef-validator.pem /etc/chef/validator.pem"`

      puts("Removing original client.pem file from server...") unless @options['quiet']

      out << `ssh -t -oStrictHostKeyChecking=no #{ chef_user }@#{ @options['address'] } "#{ sudo(@options['address']) } rm /etc/chef/client.pem"`

      #remove_client #just in case

      puts("Starting reinitialization...") unless @options['quiet']

      out << `#{ @config['helper'].knife_bootstrap_command }`

      puts(out.last) unless @options['quiet']

      #@options['multi-step'] = true # have the upload_nodes grab the new nodes

      #upload_nodes
    end
  end
end
