
class Cheftacular
  class StatelessActionDocumentation
    def environment
      @config['documentation']['stateless_action'] <<  [
        "`cft environment boot|destroy` will boot / destroy the current environment",

        [
          "    1. `boot` will spin up servers and bring them to a stable state. " +
          "This includes setting up their subdomains for the target environment.",

          "    2. `destroy` will destroy all servers needed for the target environment",

          "    3. This command will prompt when attempting to destroy servers in staging or production"
        ]
      ]

      @config['documentation']['application'] << @config['documentation']['stateless_action'].last
    end
  end

  class StatelessAction
    def environment type="boot", ask_on_destroy=false, remove=true
      ask_on_destroy = case @options['env']
                       when 'staging'    then true
                       when 'production' then true
                       else                   false
                       end

      type = ARGV[1] if ARGV[1]

      raise "Unknown type: #{ type }, can only be 'boot' or 'destroy'" unless (type =~ /boot|destroy/) == 0

      nodes = @config['getter'].get_true_node_objects(true)

      nodes = @config['parser'].exclude_nodes( nodes, [{ unless: { env: @options['env'] }}])

      @options['force_yes']  = true
      @options['in_scaling'] = true

      initial_servers = @config['cheftacular']['env_boot_nodes']["#{ @options['env'] }_nodes"]

      if initial_servers.empty?
        puts "There are no servers defined for #{ @options['env'] } in the env_boot_nodes hash in your cheftacular.yml... Exiting"

        exit
      end

      case type
      when 'boot'
        initial_servers.each_pair do |name, config_hash|
          next if nodes.map { |n| n.name }.include?(name)

          @options['node_name']   = name
          @options['flavor_name'] = config_hash.has_key?('flavor') ? config_hash['flavor'] : @config['cheftacular']['default_flavor_name']
          @options['descriptor']  = config_hash.has_key?('descriptor') ? config_hash['descriptor'] : name
          @options['with_dn']     = config_hash.has_key?('dns_config') ? @config['parser'].parse_to_dns(config_hash['dns_config']) : @config['parser'].parse_to_dns('NODE_NAME.ENV_TLD')

          puts("Preparing to boot server #{ @options['node_name'] } for #{ @options['env'] }!") unless @options['quiet']

          @config['stateless_action'].cloud_bootstrap

          sleep 15
        end

        @config['ChefDataBag'].save_server_passwords_bag

        @options['node_name'] = nil

        @options['role'] = 'all'

        @config['action'].deploy

        #TODO INTEGRATE backups TO LOAD DATA INTO THE NEWLY BOOTED ENV
      when 'destroy'
        if ask_on_destroy
          puts "Preparing to delete nodes in #{ @options['env'] }.\nEnter Y/y to confirm."

          input = STDIN.gets.chomp

          remove = false unless ( input =~ /y|Y|yes|Yes/ ) == 0
        end

        return false unless remove

        @options['delete_server_on_remove'] = true

        nodes.each do |node|
          @options['node_name'] = node.name

          puts("Preparing to destroy server #{ @options['node_name'] } for #{ @options['env'] }!") unless @options['quiet']

          @config['stateless_action'].remove_client

          sleep 15
        end
      end
    end
  end
end
