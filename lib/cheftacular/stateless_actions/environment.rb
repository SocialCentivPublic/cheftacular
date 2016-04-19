
class Cheftacular
  class StatelessActionDocumentation
    def environment
      @config['documentation']['stateless_action'][__method__] ||= {}
      @config['documentation']['stateless_action'][__method__]['long_description'] = [
        "`cft environment boot|boot_without_deploy|destroy|destroy_raw_servers [SERVER_NAMES]` will boot / destroy the current environment",

        [
          "    1. `boot` will spin up servers and bring them to a stable state. " +
          "This includes setting up their subdomains for the target environment.",

          "    2. `destroy` will destroy all servers needed for the target environment",

          "    3. `destroy_raw_servers` will destroy the servers without destroying the node data.",

          "    4. `boot_without_deploy` will spin up servers and bring them to a state where they are ready to be deployed",

          "    5. This command will prompt when attempting to destroy servers in staging or production. " + 
          "Additionally, only devops clients will be able to destroy servers in those environments.",

          "    6. This command also accepts a *comma delimited list* of server names to boot / destroy instead of all the stored ones for an environment.",

          "    7. This command works with all the flags that `cft deploy` works with, like -Z -z -O and so on.",

          "    8. Aliased to `cft e` and `cft env`"
        ]
      ]

      @config['documentation']['stateless_action'][__method__]['short_description'] = 'Boots (or destroys) an environment based on data stored in cheftacular.yml'

      @config['documentation']['application'][__method__] = @config['documentation']['stateless_action'][__method__]
    end
  end

  class StatelessAction
    def environment type="boot", ask_on_destroy=false, remove=true, servers_to_interact_with=[], threads=[]
      ask_on_destroy = case @options['env']
                       when 'staging'    then true
                       when 'production' then true
                       else                   false
                       end

      type = ARGV[1] if ARGV[1]

      servers_to_interact_with = ARGV[2].split(',') if ARGV[2]

      unless (type =~ /boot|destroy|destroy_raw_servers|boot_without_deploy/) == 0
        raise "Unknown type: #{ type }, can only be 'boot'/'boot_without_deploy'/'destroy'/'destroy_raw_servers'"
      end

      nodes = @config['getter'].get_true_node_objects(true)

      nodes = @config['parser'].exclude_nodes( nodes, [{ unless: { env: @options['env'] }}])

      @options['force_yes']  = true
      @options['in_scaling'] = true

      initial_servers = @config['cheftacular']['env_boot_nodes']["#{ @options['env'] }_nodes"]

      unless servers_to_interact_with.empty?
        initial_servers = initial_servers.delete_if {|name, config_hash| !servers_to_interact_with.include?(name)}
      end

      if initial_servers.empty?
        puts "There are no servers defined for #{ @options['env'] } in the env_boot_nodes hash in your cheftacular.yml... Exiting"

        exit
      end

      case type
      when /boot|boot_without_deploy/
        begin
          initial_servers.each_pair do |name, config_hash|
            next if nodes.map { |n| n.name }.include?(name)
            config_hash ||= {}
            node_hash     = {}

            node_hash['node_name']   = name
            node_hash['flavor_name'] = config_hash.has_key?('flavor') ? config_hash['flavor'] : @config['cheftacular']['default_flavor_name']
            node_hash['descriptor']  = config_hash.has_key?('descriptor') ? config_hash['descriptor'] : name
            node_hash['dns_config']  = if config_hash.has_key?('dns_config')
                                         @config['parser'].parse_to_dns(config_hash['dns_config'], node_hash['node_name'])
                                       else
                                         @config['parser'].parse_to_dns('NODE_NAME.ENV_TLD', node_hash['node_name'])
                                       end

            @config['server_creation_queue'] << node_hash
          end

          @config['stateless_action'].cloud_bootstrap_from_queue
        end

        @config['ChefDataBag'].save_server_passwords_bag

        if type == 'boot'
          @options = @options.delete_if { |k,v| ['node_name','address', 'descriptor', 'with_dn', 'private_address', 'client_pass'].include?(k) }

          @options['role'] = @config['cheftacular']['backup_config']['db_primary_role']

          @options['unset_address_and_node_name'] = true

          database_host = @config['parser'].exclude_nodes( @config['getter'].get_true_node_objects(true), [{ unless: "role[#{ @options['role'] }]"}, { if: { not_env: @options['env'] } }], true).first

          unless database_host.nil?
            @config['action'].deploy

            backup_pid = Process.spawn("cft backups load --env=#{ @options['env'] }")
          end

          puts("NOTE! This command is not finished until your terminal returns to an input state!") unless database_host.nil?

          @options['role'] = 'all'

          @config['action'].deploy

          Process.wait(backup_pid) unless database_host.nil?

          puts "Done loading data and setting up #{ @options['env'] }!"
        end
      when 'destroy'        
        return false if ask_on_destroy && !environment_is_destroyable?

        @options['delete_server_on_remove'] = true

        nodes.each do |node|
          @options['node_name'] = node.name

          puts("Preparing to destroy server #{ @options['node_name'] } for #{ @options['env'] }!") unless @options['quiet']

          @config['stateless_action'].remove_client

          sleep 15
        end
      when 'destroy_raw_servers'
        return false if ask_on_destroy && !environment_is_destroyable?

        @options['delete_server_on_remove'] = true

        initial_servers.each_pair do |name, config_hash|
          next if nodes.map { |n| n.name }.include?(name)
          @options['node_name'] = name

          real_node_name = @config['getter'].get_current_real_node_name

          @config['stateless_action'].cloud('servers', "destroy:#{ real_node_name }")

          sleep 15
        end
      end

      @config['auditor'].notify_slack_on_completion("environment #{ type } command completed for env: #{ @options['env'] }\n") if @config['cheftacular']['auditing']
    end

    alias_method :e, :environment
    alias_method :env, :environment

    private

    def environment_is_destroyable?
      raise "This action can only be performed if the mode is set to devops" unless @config['helper'].running_in_mode?('devops')

      puts "Preparing to delete nodes in #{ @options['env'] }.\nEnter Y/y to confirm."

      input = STDIN.gets.chomp

      ( input =~ /y|Y|yes|Yes/ ) == 0
    end
  end
end
