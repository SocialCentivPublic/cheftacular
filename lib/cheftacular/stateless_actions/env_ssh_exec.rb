
class Cheftacular
  class StatelessActionDocumentation
    def env_ssh_exec
      @config['documentation']['stateless_action'][__method__] ||= {}
      @config['documentation']['stateless_action'][__method__]['long_description'] = [
        "`cft env_ssh_exec [command]` will ssh into each server in an environment and run the command as sudo. ",

        [
          "    1. To deactivate logstash: `cft env_ssh_exec sv stop logstash_agent`",

          "    2. To view a tree of all processes running on each server, run pstree -g"
        ]
      ]

      @config['documentation']['stateless_action'][__method__]['short_description'] = 'Runs a command on all servers in an environment'

      @config['documentation']['application'][__method__] = @config['documentation']['stateless_action'][__method__]
    end
  end

  class StatelessAction
    def env_ssh_exec command='', nodes=[]
      raise "This action can only be performed if the mode is set to devops" unless @config['helper'].running_in_mode?('devops')

      command = ARGV[1] if command.blank? 

      nodes = @config['parser'].exclude_nodes( @config['getter'].get_true_node_objects(true), [{ unless: { env: @options['env'] }}] ) if nodes.empty?

      #this must always precede on () calls so they have the instance variables they need
      options, locs, ridley, logs_bag_hash, pass_bag_hash, bundle_command, cheftacular, passwords = @config['helper'].set_local_instance_vars

      on ( nodes.map { |n| @config['cheftacular']['deploy_user'] + "@" + n.public_ipaddress } ), in: :groups, limit: 5, wait: 5 do |host|
        n = get_node_from_address(nodes, host.hostname)

        log_data, timestamp = start_env_exec( n.name, n.public_ipaddress, command, options, locs, passwords)
      end
    end
  end
end

module SSHKit
  module Backend
    class Netssh
      def start_env_exec name, ip_address, command, options, locs, passwords, out=""
        log_loc, timestamp = set_log_loc_and_timestamp(locs)

        puts("Generating a log file for #{ command } at #{ name } (#{ ip_address }) at #{ log_loc }/ssh-exec/#{ name }-exec-#{ timestamp }.txt") unless options['quiet']

        out << sudo_capture( passwords[ip_address], command )

        puts(out) if options['output'] || options['verbose']

        ::File.open("#{ log_loc }/ssh-exec/#{ name }-exec-#{ timestamp }.txt", "w") { |f| f.write(out.scrub_pretty_text) } unless options['no_logs']

        puts "Succeeded run of #{ command } on #{ name } (#{ ip_address })"

        #[out, timestamp] #return out to send to logs_bag
      end
    end
  end
end
