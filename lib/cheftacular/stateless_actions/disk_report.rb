class Cheftacular
  class StatelessActionDocumentation
    def disk_report
      @config['documentation']['stateless_action'][__method__] ||= {}
      @config['documentation']['stateless_action'][__method__]['long_description'] = [
        "`cft disk_report` will fetch useful statistics from every server for every environment and output it into your log directory."
      ]

      @config['documentation']['application'][__method__] = @config['documentation']['stateless_action'][__method__]

      @config['documentation']['stateless_action'][__method__]['short_description'] = 'Retrives basic info about the filesystem for your nodes'
    end
  end

  class StatelessAction
    def disk_report disk_hash={}, out=[]
      
      nodes = @config['getter'].get_true_node_objects(true)

      nodes = @config['parser'].exclude_nodes( nodes, [{ if: { env: '_default' }}] )

      @config['chef_environments'].each do |env|
        @config['initializer'].initialize_data_bags_for_environment env, false, ['addresses', 'server_passwords']

        @config['initializer'].initialize_passwords env
      end

      options, locs, ridley, logs_bag_hash, pass_bag_hash, bundle_command, cheftacular, passwords = @config['helper'].set_local_instance_vars

      on ( nodes.map { |n| @config['cheftacular']['deploy_user'] + "@" + n.public_ipaddress } ), in: :groups, limit: 5, wait: 2 do |host|
        n = get_node_from_address(nodes, host.hostname)

        puts "Beginning disk report run for #{ n.name } (#{ n.public_ipaddress })"

        disk_hash[n.name] = start_disk_report( n.name, n.public_ipaddress, options, locs, passwords)
      end

      disk_hash.each_pair do |serv_name, output|
        out << "#{ serv_name }:"

        line_count = 1

        output.join("\n").split("\n").each do |line|
          out << line_count == 1 ? "               #{ line }" : "  #{ line }"

          line_count += 1
        end

        out << "\n"
      end

      puts(out) if @options['no_logs'] || @options['verbose']

      log_loc, timestamp = @config['helper'].set_log_loc_and_timestamp

      puts("Generating log file for disk report at #{ log_loc }/disk-report-#{ timestamp }.txt") unless @options['quiet']

      File.open("#{ log_loc }/disk-report-#{ timestamp }.txt", "w") { |f| f.write(out.join("\n").scrub_pretty_text) } unless @options['no_logs']
    end
  end
end

module SSHKit
  module Backend
    class Netssh
      def start_disk_report name, ip_address, options, locs, passwords, out=[]

        out << sudo_capture( passwords[ip_address], :free, '-m' )
        out << "\n"
        out << sudo_capture( passwords[ip_address], :df, '-aTh' )

        puts(out.join("\n")) if options['output'] || options['verbose']

        out
      end
    end
  end
end
