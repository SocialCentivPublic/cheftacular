
class Cheftacular
  class StatelessActionDocumentation
    def cloud_bootstrap
      @config['documentation']['stateless_action'] <<  [
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
    end
  end

  class StatelessAction
    def cloud_bootstrap
      raise "This action can only be performed if the mode is set to devops" if !@config['helper'].running_in_mode?('devops') && !@options['in_scaling']
      
      @options['node_name']   = ARGV[1] unless @options['node_name']
      @options['flavor_name'] = ARGV[2] unless @options['flavor_name']
      @options['descriptor']  = ARGV[3] if ARGV[3] && !@options['descriptor']
      full_domain             = ""

      if `which sshpass`.empty?
        raise "sshpass not installed! Please run brew install https://raw.github.com/eugeneoden/homebrew/eca9de1/Library/Formula/sshpass.rb (or get it from your repo for linux)"
      end

      #the output of the cloud command is a hash, this hash is UPDATED every time a rax command is run so you only need to grab it when you need it
      @config['stateless_action'].cloud "server", "create:#{ @options['env'] }_#{ @options['node_name'] }:#{ @options['flavor_name'] }"

      status_hash = @config['stateless_action'].cloud "server", "poll:#{ @options['env'] }_#{ @options['node_name'] }"

      status_hash['created_servers'].each do |server_hash|
        next unless server_hash['name'] == "#{ @options['env'] }_#{ @options['node_name'] }"

        @options['address'] = server_hash['ipv4_address']

        @options['private_address'] = server_hash['addresses']['private'][0]['addr']
      end

      begin
        @options['client_pass'] = status_hash['admin_passwords']["#{ @options['env'] }_#{ @options['node_name'] }"]
      rescue NoMethodError => e
        puts "Unable to locate an admin pass for server #{ @options['node_name'] }, does the server already exist? Exiting #{ __method__ }..."

        return false
      end

      if @options['with_dn']
        domain_obj = PublicSuffix.parse @options['with_dn']

        @config['stateless_action'].cloud "domain", "create_record:#{ domain_obj.domain }:#{ domain_obj.trd }:#{ @options['address'] }"

        sleep 5

        @config['stateless_action'].cloud "domain", "create_record:#{ domain_obj.domain }:local.#{ domain_obj.trd }:#{ @options['private_address'] }"

        full_domain = @options['with_dn']

        #set the wildcard domain for frontend load balancers
        @config['stateless_action'].cloud "domain", "create_record:#{ domain_obj.domain }:*:#{ @options['address'] }" if ( @options['node_name'] =~ /mysc.*lb/ ) == 0
      end
      
      tld = @config[@options['env']]['config_bag_hash'][@options['sub_env']]['tld']

      @config['stateless_action'].cloud "domain", "create_record:#{ tld }:#{ @options['node_name'] }:#{ @options['address'] }"

      sleep 5

      @config['stateless_action'].cloud "domain", "create_record:#{ tld }:local.#{ @options['node_name'] }:#{ @options['private_address'] }"

      full_domain = "#{ @options['node_name'] }.#{ tld }" if full_domain.blank?

      @config[@options['env']]['addresses_bag_hash'] = @config[@options['env']]['addresses_bag'].reload.to_hash

      target_serv_index = @config[@options['env']]['addresses_bag_hash']['addresses'].count

      @config[@options['env']]['addresses_bag_hash']['addresses'].each do |serv_hash|
        target_serv_index = @config[@options['env']]['addresses_bag_hash']['addresses'].index(serv_hash) if serv_hash['name'] == @options['node_name']
      end

      #EX: "name": "api1", "public": "1.2.3.4", "address": "10.208.1.2", "dn":"api1.example.com", "descriptor": "lb:my-backend-codebase"
      @config[@options['env']]['addresses_bag_hash']['addresses'][target_serv_index] ||= {}
      @config[@options['env']]['addresses_bag_hash']['addresses'][target_serv_index]['name']       = @options['node_name']
      @config[@options['env']]['addresses_bag_hash']['addresses'][target_serv_index]['public']     = @options['address']
      @config[@options['env']]['addresses_bag_hash']['addresses'][target_serv_index]['address']    = @options['private_address']
      @config[@options['env']]['addresses_bag_hash']['addresses'][target_serv_index]['dn']         = full_domain
      @config[@options['env']]['addresses_bag_hash']['addresses'][target_serv_index]['descriptor'] = @options['descriptor'].nil? ? @options['node_name'] : @options['descriptor']

      @config['ChefDataBag'].save_addresses_bag

      @options['dont_remove_address_or_server'] = true #flag to make sure our entry isnt removed in addresses bag

      full_bootstrap #bootstrap server with ruby and attach it to the chef server
    end
  end
end
