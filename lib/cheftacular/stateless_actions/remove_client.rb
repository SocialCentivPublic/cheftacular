
class Cheftacular
  class StatelessActionDocumentation
    def remove_client
      @config['documentation']['action'] <<  [
        "`cft remove_client -n NODE_NAME` removes a client (and its node data) from the chef-server. " +
        "It also removes its dns records from the cloud service (if possible). " +
        "This should not be done lightly as you will have to wipe the server and trigger another chef-client run to get it to register again"
      ]
    end
  end

  class StatelessAction
    def remove_client delete_server=false, remove=true
      @options['node_name']               = ARGV[1] unless @options['node_name']
      @options['delete_server_on_remove'] = ARGV[2] if !@options['delete_server_on_remove'] && !@options['dont_remove_address_or_server'] && ARGV[2]
      @options['delete_server_on_remove'] = 'destroy' if delete_server || @options['delete_server_on_remove']

      raise "The only valid argument for the 2nd argument of this command is 'destroy', please enter this or leave it blank." if ARGV[2] && ARGV[2] != 'destroy' && !@options['dont_remove_address_or_server']

      raise "CannotRemoveMultipleClients, Please call this script as hip remove_client <node_name>" unless @options['node_name']
      
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
            @config['stateless_action'].cloud "server", "destroy:#{ @options['env'] }_#{ n.name }"
          end
        end 

        @config[@options['env']]['addresses_bag_hash'] = @config[@options['env']]['addresses_bag'].reload.to_hash

        target_serv_index = nil

        @config[@options['env']]['addresses_bag_hash']['addresses'].each do |serv_hash|
          target_serv_index = @config[@options['env']]['addresses_bag_hash']['addresses'].index(serv_hash) if serv_hash['name'] == @options['node_name']
        end

        if !target_serv_index.nil? && target_serv_index.is_a?(Fixnum) && !@options['dont_remove_address_or_server']
          puts("Found entry in addresses data bag corresponding to #{ @options['node_name'] } for #{ @options['env'] }, removing...") unless @options['quiet']

          domain_obj = PublicSuffix.parse @config[@options['env']]['addresses_bag_hash']['addresses'][target_serv_index]['dn']

          #delete the domain on rax if its a domain we host there for its environment
          @config['stateless_action'].cloud "domain", "destroy_record:#{ domain_obj.tld }:#{ domain_obj.trd }" if domain_obj.tld == @config[@options['env']]['config_bag_hash'][@options['sub_env']]['tld']

          @config[@options['env']]['addresses_bag_hash']['addresses'][target_serv_index] = nil
          @config[@options['env']]['addresses_bag_hash']['addresses'] = @config[@options['env']]['addresses_bag_hash']['addresses'].compact
        end

        @config['ChefDataBag'].save_addresses_bag
      end

      puts("Done. Please verify that the output of the next line(s) match your expectations (running client-list)") if @options['verbose']
      
      puts(`client-list`) if @options['verbose']
    end
  end
end
