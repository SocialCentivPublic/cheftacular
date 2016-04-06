class Cheftacular
  class StatelessActionDocumentation
    def get_active_ssh_connections
      @config['documentation']['stateless_action'][__method__] ||= {}
      @config['documentation']['stateless_action'][__method__]['long_description'] = [
        "`cft get_active_ssh_connections` will fetch the active ssh connections from every server and output it into your log directory.",

        [
          "    1. This command runs on all servers in an environment by default",
          
          "    2. Packets can be examined more closely with `tcpdump src port PORT`"
        ]
      ]

      @config['documentation']['stateless_action'][__method__]['short_description'] = 'Check servers for active ssh connections'
      @config['documentation']['application'][__method__] = @config['documentation']['stateless_action'][__method__]
    end
  end

  class StatelessAction
    def get_active_ssh_connections connections_hash={}, out=[]
      nodes = @config['getter'].get_true_node_objects(true)

      nodes = @config['parser'].exclude_nodes( nodes, [{ unless: { env: @options['env'] }}] )

      options, locs, ridley, logs_bag_hash, pass_bag_hash, bundle_command, cheftacular, passwords = @config['helper'].set_local_instance_vars

      on ( nodes.map { |n| @config['cheftacular']['deploy_user'] + "@" + n.public_ipaddress } ) do |host|
        n = get_node_from_address(nodes, host.hostname)

        puts "Beginning ssh connection check run for #{ n.name } (#{ n.public_ipaddress })"

        connections_hash[n.name] = start_connection_report( n.name, n.public_ipaddress, options, locs, passwords)
      end

      @config['filesystem'].generate_report_from_node_hash('connections report', connections_hash)
    end
  end
end

module SSHKit
  module Backend
    class Netssh
      def start_connection_report name, ip_address, options, locs, passwords, out=[]

        out << capture( :netstat, '-atn', :|, :grep, ':22' )

        puts(out.join("\n")) if options['output'] || options['verbose']

        out
      end
    end
  end
end
