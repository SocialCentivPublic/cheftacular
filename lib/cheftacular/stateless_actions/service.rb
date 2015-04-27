
class Cheftacular
  class StatelessActionDocumentation
    def service
      @config['documentation']['stateless_action'] <<  [
        "`cft service [COMMAND] [SERVICE]` will run service commands on remote servers. " +
        "This command only runs on the first server it comes across. Specify others with -n NODE_NAME.",

        [
          "    1. When no commands are passed, the command will list all the services in the /etc/init directory",

          "    2. When `list` is passed, the above behavior is performed ",

          "    3. When `restart|stop|start SERVICE` is passed, the command will attempt to restart|stop|start the " + 
          "service if it has a .conf file on the remote server in the /etc/init directory."
        ]
      ]
    end
  end

  class StatelessAction
    def service
      raise "This action can only be performed if the mode is set to devops" unless @config['helper'].running_in_mode?('devops')

      command = case ARGV[1]
                when nil                then 'list'
                when /list/             then 'list'
                when 'restart'          then "#{ ARGV[2] } restart"
                when 'stop'             then "#{ ARGV[2] } stop"
                when 'start'            then "#{ ARGV[2] } start"
                else                         'list'
                end

      raise "You did not pass a service to #{ ARGV[1] }" if ARGV[1] =~ /restart|stop|start/ && ARGV[2].nil?

      service_location = "#{ ARGV[2] }.conf"

      nodes = @config['getter'].get_true_node_objects

      nodes = @config['parser'].exclude_nodes( nodes, [{ unless: { env: @options['env'] }}], true )

      options, locs, ridley, logs_bag_hash, pass_bag_hash, bundle_command, cheftacular, passwords = @config['helper'].set_local_instance_vars

      on ( nodes.map { |n| "deploy@" + n.public_ipaddress } ) do |host|
        n = get_node_from_address(nodes, host.hostname)

        puts "Beginning run of \"service #{ command }\" for #{ n.name } (#{ n.public_ipaddress })"

        start_service_run( n.name, n.public_ipaddress, options, locs, passwords, command, cheftacular, service_location )
      end
    end
  end
end

module SSHKit
  module Backend
    class Netssh
      def start_service_run name, ip_address, options, locs, passwords, command, cheftacular, service_location, out=""
        log_loc, timestamp = set_log_loc_and_timestamp(locs)
        run_list_command   = command == 'list'

        #puts "Generating service run log file for #{ name } (#{ ip_address }) at #{ log_loc }/rolelog/#{ name }-service-#{ timestamp }.txt"

        #TODO check other locations for services!
        if !run_list_command && !sudo_test( passwords[ip_address], "/etc/init/#{ service_location }" ) #true if file exists
          puts "#{ name } (#{ ip_address }) cannot run #{ command } as it's .conf file does not exist! Running list instead..."

          run_list_command = true
        end

        if run_list_command
          out << capture( :ls, '-al', '/etc/init' ) 
        else
          out << sudo_capture( passwords[ip_address], 'service', command)
        end

        #::File.open("#{ log_loc }/rolelog/#{ name }-service-#{ timestamp }.txt", "w") { |f| f.write(out.scrub_pretty_text) } unless options['no_logs']

        puts out.scrub_pretty_text

        puts "Succeeded run of \"service #{ command }\" for #{ name } (#{ ip_address })"
      end
    end
  end
end
