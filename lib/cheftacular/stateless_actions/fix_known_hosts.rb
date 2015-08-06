
class Cheftacular
  class StatelessActionDocumentation
    def fix_known_hosts
      @config['documentation']['stateless_action'] <<  [
        "`cft fix_known_hosts [HOSTNAME]` this command will delete entries in your known_hosts file " +
        "for all the servers that are in our system (ip addresses AND dns names)",

        [
          "    1. Passing in a hostname will make the command only remove entries with that hostname / ip specifically"
        ]
      ]

      @config['documentation']['application'] << @config['documentation']['stateless_action'].last
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
            arr << serv_hash['dn'].split('.').first
            arr << serv_hash['public']
          end
        end

        targets = arr.uniq
      end

      targets.each do |target|
        puts "clearing #{ target }"
        case CONFIG['host_os']
        when /mswin|windows/i
          raise "#{ __method__ } does not support this operating system at this time"
        when /linux|arch/i
          puts "#{ __method__ } does not support this operating system at this time"
        when /sunos|solaris/i
          raise "#{ __method__ } does not support this operating system at this time"
        when /darwin/i
          cleanup_known_hosts_for_BSD_linux_architecture target
        else
          raise "#{ __method__ } does not support this operating system at this time"
        end
      end
    end
    private

    def cleanup_known_hosts_for_BSD_linux_architecture target
      #Removes the entire line containing the string
      `sed -i '' "s/#{ target }.*//g" ~/.ssh/known_hosts`

      #remove empty lines
      `sed -i '' "/^$/d" ~/.ssh/known_hosts`
    end
  end
end
