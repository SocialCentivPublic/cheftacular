
class Cheftacular
  class StatelessActionDocumentation
    def fix_known_hosts
      @config['documentation']['stateless_action'][__method__] ||= {}
      @config['documentation']['stateless_action'][__method__]['long_description'] = [
        "`cft fix_known_hosts [HOSTNAME]` this command will delete entries in your known_hosts file " +
        "for all the servers that are in our system (ip addresses AND dns names)",

        [
          "    1. Passing in a hostname will make the command only remove entries with that hostname / ip specifically",

          "    2. Aliased to `cft fkh`"
        ]
      ]

      @config['documentation']['stateless_action'][__method__]['short_description'] = 'Fixes issues with the known_hosts ssh file'

      @config['documentation']['application'][__method__] = @config['documentation']['stateless_action'][__method__]
    end
  end

  class StatelessAction
    def fix_known_hosts
      targets = ["all"]

      if ARGV[1].class == String
        targets = [ARGV[1]]
      end

      if targets.first == 'all'
        nodes = @config['getter'].get_true_node_objects(true)
        arr = []

        @config['chef_environments'].each do |env|
          @config['initializer'].initialize_data_bags_for_environment env, false, ['addresses']

          @config['initializer'].initialize_addresses_bag_contents env

          @config[env]['addresses_bag_hash']['addresses'].each do |serv_hash|
            arr << serv_hash['dn']
            arr << serv_hash['public']
          end
        end

        targets = arr.uniq
      end

      targets.each do |target|
        @config['filesystem'].scrub_from_known_hosts target
      end
    end

    alias_method :fkh, :fix_known_hosts
  end
end
