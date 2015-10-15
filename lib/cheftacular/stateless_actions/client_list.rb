
class Cheftacular
  class StatelessActionDocumentation
    def client_list
      @config['documentation']['stateless_action'][__method__] ||= {}
      @config['documentation']['stateless_action'][__method__]['long_description'] = [
        "`cft client_list` Allows you check the basic information for all the servers setup via chef. " +
        "Shows the server's short name, its public ip address and roles (run_list) by default.",

        [
          "    1. `-v` option will make this command display the server's domain name, " +
          "whether its password is stored on the chef server and what that password is.",

          "    2. `-W|--with-priv` option will make this command display the server's local (private) ip address. " + 
          "This address is also the server's `local.<SERVER_DNS_NAME>`.",

          "    3. This command is aliased to `client-list` with no arguments or cft prefix."
        ]
      ]

      @config['documentation']['stateless_action'][__method__]['short_description'] = 'Retrieves useful information for all servers in all environments'

      @config['documentation']['application'][__method__] = @config['documentation']['stateless_action'][__method__]
    end
  end

  class StatelessAction
    def client_list
      @config['filesystem'].cleanup_file_caches('current-nodes')

      nodes = @config['getter'].get_true_node_objects(true)

      @config['chef_environments'].each do |env|
        @config['initializer'].initialize_data_bags_for_environment env, false, ['addresses', 'server_passwords']
      end

      environments = nodes.map { |n| n.chef_environment }

      environments.uniq.each do |env|
        next if env == '_default'

        env_nodes = @config['parser'].exclude_nodes(nodes, [{ if: { not_env: env } }])
        puts "\nFound #{ env_nodes.count } #{ env } nodes:"
        out = "  #{ 'name'.ljust(22) } #{ 'ip_address'.ljust(21) }"
        out << "#{ 'private_address'.ljust(21) }"                   if @options['with_private']
        out << "#{ 'pass?'.ljust(5) } #{ 'domain'.ljust(41) }"      if @options['verbose']
        out << "#{ 'deploy_password'.ljust(21) }"                   if @options['verbose']
        out << "run_list"

        puts out

        auth_hash = @config[env]['server_passwords_bag_hash']

        addresses_hash = @config['getter'].get_addresses_hash env

        env_nodes.each do |node|
          #client = @ridley.client.find(options['node_name'])
          out = "  #{ node.chef_id.ljust(22,'_') }_#{ node.public_ipaddress.ljust(20,'_') }"

          if @options['with_private']
            if addresses_hash.has_key?(node.public_ipaddress)
              out << addresses_hash[node.public_ipaddress]['address'].ljust(20,'_')
            else
              out << ''.ljust(20,'_')
            end
          end

          if @options['verbose']

            out << "_" + auth_hash.has_key?("#{ node.public_ipaddress }-deploy-pass").to_s.ljust(5,'_') + "_"

            if addresses_hash.has_key?(node.public_ipaddress)
              out << addresses_hash[node.public_ipaddress]['dn'].ljust(40,'_')
            else
              out << ''.ljust(40,'_')
            end

            if auth_hash.has_key?("#{ node.public_ipaddress }-deploy-pass")
              out << "_" + auth_hash["#{ node.public_ipaddress }-deploy-pass"]
            else
              out << "_" + ''.ljust(@config['cheftacular']['server_password_length'],'_')
            end
          end

          out << "_#{ node.run_list.join(', ') }"
          
          puts out
        end
      end
    end
  end
end
