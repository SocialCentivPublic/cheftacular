
class Cheftacular
  class StatelessActionDocumentation
    def cloud_bootstrap
      @config['documentation']['stateless_action'][__method__] ||= {}
      @config['documentation']['stateless_action'][__method__]['long_description'] = [
        "`cft cloud_bootstrap NODE_NAME FLAVOR_NAME [DESCRIPTOR] [--with-dn DOMAIN]` uses a cloud api to " +
        "create a server and attaches its DOMAIN_NAME to the TLD specified for that environment (IE: example-staging.com for staging)",

        [
          "    1. If no DOMAIN_NAME is supplied it will use the node's NODE_NAME (IE: api01.example-staging.com)",

          "    2. If the `--with-dn DOMAIN` argument is supplied the rax api will attempt to attach the node to the " +
          "top level domain instead of the default environment one. This tld must be attached to the cloud service. "+
          "This also allows you to attach to custom subdomains instead of NODE_NAME.ENV_TLD",

          "    3. `cft cloud_bootstrap myserver \"1 GB Performance\" --with-dn myserver.example-staging.com` " +
          'The "1 GB Perfomance" does not have to be exact, "1 GB" will match "1 GB Performance" and "1GB" ' +
          "will match \"1GB Standard\" (for rackspace flavors)",

          "    4. DESCRIPTOR is used as an internal tag for the node, if left blank it will become the name of the node. " +
          "It is recommended to enter a custom repository-dependent tag here to make nodes easier to load-balance like \"lb:[CODEBASE_NAME]\""
        ]
      ]

      @config['documentation']['stateless_action'][__method__]['short_description'] = 'Uses the cloud API to setup a server and bring it to a deployable state'
    end
  end

  class StatelessAction
    def cloud_bootstrap server_hash={}, options_to_sync=['node_name', 'flavor_name', 'descriptor', 'dns_config', 'address', 'private_address', 'client_pass']
      raise "This action can only be performed if the mode is set to devops" if !@config['helper'].running_in_mode?('devops') && !@options['in_scaling']
      
      @options['node_name']   = server_hash['node_name']   if server_hash.has_key?('node_name')
      @options['flavor_name'] = server_hash['flavor_name'] if server_hash.has_key?('flavor_name')
      @options['descriptor']  = server_hash['descriptor']  if server_hash.has_key?('descriptor')
      @options['with_dn']     = server_hash['dns_config']  if server_hash.has_key?('dns_config')

      @options['node_name']   = ARGV[1] unless @options['node_name']
      @options['flavor_name'] = ARGV[2] unless @options['flavor_name']
      @options['descriptor']  = ARGV[3] if ARGV[3] && !@options['descriptor']

      @options['in_single_server_creation'] = true

      puts "Preparing to boot #{ @options['node_name'] }(#{ @options['flavor_name'] })..."

      real_node_name = @config['getter'].get_current_real_node_name

      #the output of the cloud command is a hash, this hash is UPDATED every time a rax command is run so you only need to grab it when you need it
      @config['stateless_action'].cloud "server", "create:#{ real_node_name }:#{ @options['flavor_name'] }"

      status_hash = @config['stateless_action'].cloud "server", "poll:#{ real_node_name }"

      status_hash['created_servers'].each do |cloud_server_hash|
        next unless cloud_server_hash['name'] == "#{ real_node_name }"

        @options['address'], @options['private_address'] = @config['cloud_provider'].parse_addresses_from_server_create_hash cloud_server_hash
      end

      @options['client_pass'] = @config['cloud_provider'].parse_server_root_password_from_server_create_hash status_hash, real_node_name
      tld                     = @config[@options['env']]['config_bag_hash'][@options['sub_env']]['tld']
      target_serv_index       = @config[@options['env']]['addresses_bag_hash']['addresses'].count
      compile_args            = ['set_all_attributes']
      compile_args           << "set_specific_domain:#{ @options['with_dn'] }" if @options['with_dn']
      address_hash            = @config['DNS'].compile_address_hash_for_server_from_options(*compile_args)

      @config['DNS'].create_dns_record_for_domain_from_address_hash(@options['with_dn'], address_hash, "specific_domain_mode") if @options['with_dn']

      @config['DNS'].create_dns_record_for_domain_from_address_hash(tld, address_hash)
      
      @config['ChefDataBag'].save_addresses_bag

      @options['dont_remove_address_or_server'] = true #flag to make sure our entry isnt removed in addresses bag

      server_hash = @config['queue_master'].sync_server_hash_into_queue(server_hash.merge(@config['helper'].return_options_as_hash(options_to_sync)))

      puts("Created server #{ server_hash['node_name'] } and attached additional flags:")                                                  unless @options['quiet']
      ap(@config['queue_master'].return_hash_from_queue('server_creation_queue', server_hash, 'node_name').except(*options_to_sync[0..3])) unless @options['quiet']

      @config['stateless_action'].full_bootstrap_from_queue unless @config['in_server_creation_queue'] #bootstrap server with ruby and attach it to the chef server
    end
  end
end
