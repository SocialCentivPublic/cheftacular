
class Cheftacular
  class StatelessActionDocumentation
    def remove_client
      @config['documentation']['stateless_action'][__method__] ||= {}
      @config['documentation']['stateless_action'][__method__]['long_description'] = [
        "`cft remove_client NODE_NAME [destroy]` removes a client (and its node data) from the chef-server. " +
        "It also removes its dns records from the cloud service (if possible). " +
        "This should not be done lightly as you will have to wipe the server and trigger another chef-client " +
        "run to get it to register again. Alternatively, you can run `cft reinitialize IP_ADDRESS NODE_NAME as well.",

        [
          "    1. `destroy` deletes the server as well as removing it from the chef environment.",

          "    2. This command is aliased to `cft remove_node`"
        ]
      ]

      @config['documentation']['stateless_action'][__method__]['short_description'] = 'Removes a node from the chef server'
    end
  end

  class StatelessAction
    def remove_client delete_server=false, remove=true
      @options['node_name']               = ARGV[1] unless @options['node_name']
      @options['delete_server_on_remove'] = ARGV[2] if !@options['delete_server_on_remove'] && !@options['dont_remove_address_or_server'] && ARGV[2]
      @options['delete_server_on_remove'] = 'destroy' if delete_server || @options['delete_server_on_remove']

      raise "This action can only be performed if the mode is set to devops" if !@config['helper'].running_in_mode?('devops') && !@options['in_scaling']

      raise "The only valid argument for the 2nd argument of this command is 'destroy', please enter this or leave it blank." if ARGV[2] && ARGV[2] != 'destroy' && !@options['dont_remove_address_or_server']

      raise "Invalid arguments! Node name is blank. Please call this script as cft remove_client <node_name>" unless @options['node_name']
      
      nodes = @config['getter'].get_true_node_objects(false, true)

      nodes.each do |n|
        begin
          client = @config['ridley'].client.find(@options['node_name'])
        rescue StandardError => e
          puts "Client #{ @options['node_name'] } not found."
          return false
        end

        if @options['env'] == 'production' && !@options['force_yes']
          puts "Preparing to delete #{ @options['node_name'] } (#{ n.public_ipaddress }).\nEnter Y/y to confirm."

          input = STDIN.gets.chomp

          remove = false unless ( input =~ /y|Y|yes|Yes/ ) == 0
        end

        if remove
          puts "Removing #{ n.name } (#{ n.public_ipaddress }) from node and client list"

          @config['ridley'].node.delete(n)
          @config['ridley'].client.delete(client)

          if @options['delete_server_on_remove'] == 'destroy'
            @config['stateless_action'].cloud "server", "destroy:#{ @config['getter'].get_current_real_node_name(n.name) }"
          end

          @config[@options['env']]['addresses_bag_hash'] = @config[@options['env']]['addresses_bag'].reload.to_hash

          @config['DNS'].compile_address_hash_for_server_from_options('set_hash_to_nil')

          @config['ChefDataBag'].save_addresses_bag
        end
      end
      
      puts("Done. Please verify that the output of the next line(s) match your expectations (running client-list)") if @options['verbose']
      
      puts(`client-list`) if @options['verbose']
    end

    alias_method :remove_node, :remove_client
  end
end
