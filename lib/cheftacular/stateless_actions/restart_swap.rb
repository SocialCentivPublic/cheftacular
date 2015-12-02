class Cheftacular
  class StatelessActionDocumentation
    def restart_swap
      @config['documentation']['stateless_action'][__method__] ||= {}
      @config['documentation']['stateless_action'][__method__]['long_description'] = [
        "`cft restart_swap` will restart the swap on every server that doesn't have swap currently on. " +
        "Useful if you notice servers with no swap activated from `cft disk_report`",

        [
          "    1. There is no risk in running this command. Sometimes swap doesnt reactivate if " +
          "the server was rebooted and this command fixes that."
        ]
      ]

      @config['documentation']['stateless_action'][__method__]['short_description'] = 'Restarts the swap on all servers'
    end
  end

  class StatelessAction
    def restart_swap
      nodes = @config['getter'].get_true_node_objects(true)

      nodes = @config['parser'].exclude_nodes( nodes, [{ if: { env: '_default' }}] )

      #this must always precede on () calls so they have the instance variables they need
      options, locs, ridley, logs_bag_hash, pass_bag_hash, bundle_command, cheftacular, passwords = @config['helper'].set_local_instance_vars

      on ( nodes.map { |n| @config['cheftacular']['deploy_user'] + "@" + n.public_ipaddress } ), in: :groups, limit: 5, wait: 2 do |host|
        n = get_node_from_address(nodes, host.hostname)

        puts "Beginning swap restart run for #{ n.name } (#{ n.public_ipaddress })"

        start_swap_restart( n.name, n.public_ipaddress, options, locs, cheftacular, passwords)
      end
    end
  end
end

module SSHKit
  module Backend
    class Netssh

      def start_swap_restart name, ip_address, options, locs, cheftacular, passwords, out=[]

        if test("[ -e #{ cheftacular['default_swap_location'] } ]") #true if file exists
          check = capture( :cat, '/proc/swaps' )

          out << sudo_capture( options['pass'][ip_address], :swapon, cheftacular['default_swap_location'] ) unless check.include?(cheftacular['default_swap_location'])

          puts(out.join("\n")) if options['output'] || options['verbose']
        else
          puts "Node #{ name } (#{ ip_address }) has not had swap initialized! Skipping..."
        end
      end
    end
  end
end
