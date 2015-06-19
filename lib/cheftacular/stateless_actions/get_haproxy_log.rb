
class Cheftacular
  class StatelessActionDocumentation
    def get_haproxy_log
      @config['documentation']['stateless_action'] <<  [
        "`cft get_haproxy_log` this command will generate a haproxy html file for the load balancer(s) associated with a repository in the log directory. " +
        "Opening this log file in the browser will show the status of that haproxy at the time of the log. ",

        [
          "    1. In devops mode, this command will not do anything without the -R repository passed."
        ]
      ]

      @config['documentation']['application'] << @config['documentation']['stateless_action'].last
    end
  end

  class StatelessAction
    def get_haproxy_log
      nodes = @config['getter'].get_true_node_objects true

      nodes = @config['parser'].exclude_nodes( nodes, [{ unless: "role[#{ @config['cheftacular']['haproxy_config']['role_name'] }]" }, { if: { not_env: @options['env'] } }])

      #this must always precede on () calls so they have the instance variables they need
      options, locs, ridley, logs_bag_hash, pass_bag_hash, bundle_command, cheftacular, passwords = @config['helper'].set_local_instance_vars

      #on is namespaced to SSHKit::Backend::Netssh.on 
      on ( nodes.map { |n| @config['cheftacular']['deploy_user'] + "@" + n.public_ipaddress } ) do |host|
        n = get_node_from_address(nodes, host.hostname)

        puts("Beginning haproxy log generation run for #{ n.name } (#{ n.public_ipaddress })") unless options['quiet']

        start_haproxy_log_generator( n.name, n.public_ipaddress, options, locs, cheftacular, passwords)
      end
    end
  end
end

module SSHKit
  module Backend
    class Netssh
      def start_haproxy_log_generator name, ip_address, options, locs, cheftacular, passwords, out=[]
        log_loc, timestamp = set_log_loc_and_timestamp(locs)

        puts("Generating log file for haproxy for #{ name } (#{ ip_address }) at #{ log_loc }/#{ name }-haproxy-#{ timestamp }.html") unless options['quiet']

        out << sudo_capture( passwords[ip_address], :curl, "localhost:#{ cheftacular['haproxy_config']['default_port'] }" )

        ::File.open("#{ log_loc }/#{ name }-haproxy-#{ timestamp }.html", "w") { |f| f.write(out.join("\n").scrub_pretty_text.gsub('[sudo] password for deploy: ', '')) } unless options['no_logs']
              
        puts(out) if options['output'] || options['verbose']
      end
    end
  end
end
