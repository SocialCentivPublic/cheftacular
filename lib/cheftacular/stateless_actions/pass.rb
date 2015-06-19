
class Cheftacular
  class StatelessActionDocumentation
    def pass
      @config['documentation']['stateless_action'] <<  [
        "`cft pass NODE_NAME` will drop the server's sudo password into your clipboard. " +
        "Useful for when you need to ssh into the server itself and try advanced linux commands"
      ]

      @config['documentation']['application'] << @config['documentation']['stateless_action'].last
    end
  end

  class StatelessAction
    def pass
      @options['node_name'] = ARGV[1] unless @options['node_name']

      nodes = @config['error'].is_valid_node_name_option?

      if nodes.first.chef_environment != @options['env']
        @config['initializer'].initialize_data_bags_for_environment nodes.first.chef_environment, false, ['server_passwords']
      end

      puts "The password for #{ nodes.first.name }(#{ nodes.first.public_ipaddress }) for env #{ nodes.first.chef_environment }" +
      " is #{ @config[nodes.first.chef_environment]['server_passwords_bag_hash']["#{ nodes.first.public_ipaddress }-deploy-pass"] }"

      case CONFIG['host_os']
      when /mswin|windows/i
        raise "#{ __method__ } does not support this operating system at this time"
      when /linux|arch/i
        raise "#{ __method__ } does not support this operating system at this time"
      when /sunos|solaris/i
        raise "#{ __method__ } does not support this operating system at this time"
      when /darwin/i
        puts "Copying #{ nodes.first.name } (#{ nodes.first.public_ipaddress }) sudo password into your clipboard"
        
        `echo '#{ @config[nodes.first.chef_environment]['server_passwords_bag_hash']["#{ nodes.first.public_ipaddress }-deploy-pass"] }' | pbcopy`
      else
        raise "#{ __method__ } does not support this operating system at this time"
      end
    end
  end
end
