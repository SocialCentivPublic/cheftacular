
class Cheftacular
  class StatelessActionDocumentation
    def server_update
      @config['documentation']['stateless_action'][__method__] ||= {}
      @config['documentation']['stateless_action'][__method__]['long_description'] = [
        "`cft server_update [restart]` allows you to force update all nodes' packages for a specific environment. " + 
        "This should be done with caution as this *might* break something.",

        [
          "    1. `cft server_update restart` will prompt to ask if you also want to restart all servers in a rolling restart. " +
          "This should be done with extreme caution and only in a worst-case scenario."
        ]
      ]

      @config['documentation']['stateless_action'][__method__]['short_description'] = 'Attempts to update all servers for an env to their latest packages'
    end
  end

  class StatelessAction
    #TODO refactor to handling multiple server types
    def server_update
      raise "This action can only be performed if the mode is set to devops" unless @config['helper'].running_in_mode?('devops')

      @options['rolling_restart'] = true if ARGV[1] && ARGV[1] == 'restart'

      if @options['rolling_restart']
        puts "Preparing to do a rolling restart for all servers in env: #{ @options['env'] } (potential data loss).\nEnter Y/y to confirm, Q/q to exit completely."

        input = STDIN.gets.chomp

        @options['rolling_restart'] = false unless ( input =~ /y|Y|yes|Yes/ ) == 0

        exit if ( input =~ /y|Y|quit|Quit/ ) == 0
      end
      
      nodes = @config['getter'].get_true_node_objects true

      nodes = @config['parser'].exclude_nodes( nodes, [{ unless: { env: @options['env'] }}] )

      #this must always precede on () calls so they have the instance variables they need
      options, locs, ridley, logs_bag_hash, pass_bag_hash, bundle_command, cheftacular, passwords = @config['helper'].set_local_instance_vars

      on ( nodes.map { |n| @config['cheftacular']['deploy_user'] + "@" + n.public_ipaddress } ), in: :groups, limit: 5, wait: 5 do |host|
        n = get_node_from_address(nodes, host.hostname)

        puts "Beginning apt-get run for #{ n.name } (#{ n.public_ipaddress })"

        log_data, timestamp = start_apt_updater( n.name, n.public_ipaddress, options, locs, passwords)

        #logs_bag_hash["#{ n.name }-upgrade"] = { text: log_data.scrub_pretty_text, timestamp: timestamp }
      end

      on ( nodes.map { |n| @config['cheftacular']['deploy_user'] + "@" + n.public_ipaddress } ), in: :groups, limit: 5, wait: 120 do |host|
        n = get_node_from_address(nodes, host.hostname)

        puts "Beginning restart run for #{ n.name } (#{ n.public_ipaddress })"

        start_sys_restarter( n.name, n.public_ipaddress, options, locs, passwords)
      end if @options['rolling_restart']

      #@config['ChefDataBag'].save_logs_bag
    end
  end
end

module SSHKit
  module Backend
    class Netssh
      def start_apt_updater name, ip_address, options, locs, passwords, out=""
        log_loc, timestamp = set_log_loc_and_timestamp(locs)

        puts("Generating apt-get log file for #{ name } (#{ ip_address }) at #{ log_loc }/server-update/#{ name }-upgrade-#{ timestamp }.txt") unless options['quiet']

        out << sudo_capture( passwords[ip_address], 'apt-get', 'update' )
        out << sudo_capture( passwords[ip_address], 'apt-get', 'upgrade', '-y', '-o' 'Dpkg::Options::="--force-confnew"' )

        puts(out) if options['output'] || options['verbose']

        ::File.open("#{ log_loc }/server-update/#{ name }-apt-update-#{ timestamp }.txt", "w") { |f| f.write(out.scrub_pretty_text) } unless options['no_logs']

        puts "Succeeded upgrade of #{ name } (#{ ip_address })"

        [out, timestamp] #return out to send to logs_bag
      end

      def start_sys_restarter name, ip_address, options, locs, passwords, out=""
        log_loc, timestamp = set_log_loc_and_timestamp(locs)

        out << sudo_capture( passwords[ip_address], 'shutdown', '1', '-r' )

        ::File.open("#{ log_loc }/server-update/#{ name }-upgrade-#{ timestamp }.txt", "w") { |f| f.write(out.scrub_pretty_text) }

        puts(out) if options['output'] || options['verbose']

        puts "Succeeded restart of #{ name } (#{ ip_address })"

        [out, timestamp] #return out to send to logs_bag
      end
    end
  end
end
