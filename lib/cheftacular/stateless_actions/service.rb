
class Cheftacular
  class StatelessActionDocumentation
    def service
      @config['documentation']['stateless_action'][__method__] ||= {}
      @config['documentation']['stateless_action'][__method__]['long_description'] = [
        "`cft service [COMMAND] [SERVICE]` will run service commands on remote servers. " +
        "This command only runs on the first server it comes across. Specify others with -n NODE_NAME.",

        [
          "    1. When no commands are passed, the command will list all the services in the /etc/init directory",

          "    2. When `list` is passed, the above behavior is performed ",

          "    3. When `restart|stop|start SERVICE` is passed, the command will attempt to restart|stop|start the " + 
          "service if it has a .conf file on the remote server in the /etc/init directory.",

          "    4. `--sv` will use sv syntax for processes that use runsv instead of the older service paradigm."
        ]
      ]

      @config['documentation']['stateless_action'][__method__]['short_description'] = 'Allows you to interact with a service running on a server'
    end
  end

  class StatelessAction
    def service
      #raise "This action can only be performed if the mode is set to devops" unless @config['helper'].running_in_mode?('devops')

      command = case ARGV[1]
                when nil                then 'ls /etc/init'
                when /list/             then 'ls /etc/init'
                when 'restart'          then "service #{ ARGV[2] } restart"
                when 'stop'             then "service #{ ARGV[2] } stop"
                when 'start'            then "service #{ ARGV[2] } start"
                else                         'ls /etc/init'
                end

      command = case ARGV[1]
                when nil                then 'ls /etc/init.d'
                when /list/             then 'ls /etc/init.d'
                when 'restart'          then "sv restart #{ ARGV[2] }"
                when 'stop'             then "sv stop #{ ARGV[2] }"
                when 'start'            then "sv start #{ ARGV[2] }"
                else                         'ls /etc/init.d'
                end if @options['runsv']

      raise "You did not pass a service to #{ ARGV[1] }" if ARGV[1] =~ /restart|stop|start/ && ARGV[2].nil?

      #initctl list | awk '{ print $1 }' | xargs -n1 initctl show-config
      nodes = @config['getter'].get_true_node_objects

      nodes = @config['parser'].exclude_nodes( nodes, [{ unless: { env: @options['env'] }}], true )

      options, locs, ridley, logs_bag_hash, pass_bag_hash, bundle_command, cheftacular, passwords = @config['helper'].set_local_instance_vars

      on ( nodes.map { |n| @config['cheftacular']['deploy_user'] + "@" + n.public_ipaddress } ) do |host|
        n = get_node_from_address(nodes, host.hostname)

        puts "Beginning run of \"#{ command }\" for #{ n.name } (#{ n.public_ipaddress })"

        start_service_run( n.name, n.public_ipaddress, options, locs, passwords, command, cheftacular)
      end
    end
  end
end

module SSHKit
  module Backend
    class Netssh
      def start_service_run name, ip_address, options, locs, passwords, command, cheftacular, out=""
        log_loc, timestamp = set_log_loc_and_timestamp(locs)

        out << sudo_capture( passwords[ip_address], command)

        puts out.scrub_pretty_text

        puts "Succeeded run of \"service #{ command }\" for #{ name } (#{ ip_address })"
      end
    end
  end
end
