class Cheftacular
  class StatelessActionDocumentation
    def get_shorewall_allowed_connections
      @config['documentation']['stateless_action'] <<  [
        "`cft get_shorewall_allowed_connections [PATH_TO_LOCAL_FILE] -n NODE_NAME` command will query a single server and return all of its ACCEPT connections " +
        "from shorewall in it's syslog and return the results in a CSV format. Useful for tracking IP activity.",

        [
          "    1. You must pass in a node name to query with `-n NODE_NAME`",

          "    2. This command will attempt to `dig` each ip address to give you the most likely culprit.",

          "    3. If `PATH_TO_LOCAL_FILE` is not blank, the command will use that file instead of building a file on the remote server"
        ]
      ]
    end
  end

  class StatelessAction
    def get_shorewall_allowed_connections master_log_data=''

      if ARGV[1].nil?
        raise "Please pass a NODE_NAME with -n NODE_NAME" if @options['node_name'].nil? || @options['node_name'].empty?

        nodes = @config['getter'].get_true_node_objects true

        nodes = @config['parser'].exclude_nodes(nodes, [{ unless: { env: @options['env'] }}, { unless: { node: @options['node_name'] }}], true)

        #this must always precede on () calls so they have the instance variables they need
        options, locs, ridley, logs_bag_hash, pass_bag_hash, bundle_command, cheftacular, passwords = @config['helper'].set_local_instance_vars

        #on is namespaced to SSHKit::Backend::Netssh.on 
        on ( nodes.map { |n| @config['cheftacular']['deploy_user'] + "@" + n.public_ipaddress } ) do |host|
          n = get_node_from_address(nodes, host.hostname)

          puts("Beginning shorewall log capture run for #{ n.name } (#{ n.public_ipaddress })") unless options['quiet']

          master_log_data = start_shorewall_log_capture( n.name, n.public_ipaddress, options, locs, cheftacular, passwords)
        end
      else
        master_log_file = ARGV[1]

        raise "File not found! Did you enter the path correctly?" unless File.exist?(master_log_file)

        master_log_data = File.read(File.expand_path(master_log_file))
      end

      puts("Parsing addresses from log data...") unless @options['quiet']

      addresses = {}

      master_log_data.scan(/^.*Shorewall:net2fw:ACCEPT.*SRC=([\d]+\.[\d]+\.[\d]+\.[\d]+) DST.*DPT=80.*$/).each do |ip_address|
        addresses[ip_address] ||= 0
        addresses[ip_address] += 1
      end

      final_addresses = {}
      check_count = 0
      addresses.each_pair do |address, count|
        next if count < 100
        
        domain = `dig +short -x #{ address[0] }`.chomp.split("\n").join('|')
        domain = domain[0..(domain.length-2)]

        domain = address[0] if domain.blank?

        final_addresses[domain] ||= {}
        final_addresses[domain]['addresses'] ||= []
        final_addresses[domain]['addresses'] <<  address[0] unless final_addresses[domain]['addresses'].include?(address[0])
        final_addresses[domain]['count']     =   count   unless final_addresses[domain].has_key?('count')
        final_addresses[domain]['count']     +=  count   if final_addresses[domain].has_key?('count')

        check_count += 1

        puts("Processed #{ check_count } addresses (#{ address[0] }):#{ domain }:#{ count }") unless @options['quiet']
      end

      final_addresses = final_addresses.sort_by {|key, value_hash| value_hash['count']}.to_h

      final_addresses = Hash[final_addresses.to_a.reverse]

      ap(final_addresses) if @options['verbose']

      log_loc, timestamp = @config['helper'].set_log_loc_and_timestamp

      CSV.open(File.expand_path("#{ @config['locs']['chef-log'] }/shorewall-parse-#{ timestamp }.csv"), "wb") do |csv| 
        final_addresses.each_pair do |dns, info_hash|
          csv << [dns, info_hash['addresses'].join('|'), info_hash['count']]
        end
      end
    end
  end
end

module SSHKit
  module Backend
    class Netssh
      def start_shorewall_log_capture name, ip_address, options, locs, cheftacular, passwords, out=[]
        log_loc, timestamp = set_log_loc_and_timestamp(locs)

        puts("Generating master log file for shorewall for #{ name } (#{ ip_address }) at #{ log_loc }/#{ name }-shorewall-#{ timestamp }.html") unless options['quiet']

        syslog_files = capture(:ls, '/var/log', :|, :grep, :syslog).split("\n")

        puts("Found #{ syslog_files.count } syslog files to parse (#{ syslog_files.join(', ') }).\nPreparing to parse...") unless options['quiet']

        syslog_files.each do |file|
          puts("Parsing #{ file } into master log file...") unless options['quiet']

          if file.include?('.gz')
            sudo_execute(passwords[ip_address], :gunzip, '-c', "/var/log/#{ file }", '>>', '/tmp/syslog_master.log' )
          else
            sudo_execute(passwords[ip_address], :cat, "/var/log/#{ file }", '>>', '/tmp/syslog_master.log' )
          end
        end

        puts("Writing master log...") unless options['quiet']

        out << sudo_capture( passwords[ip_address], :cat, "/tmp/syslog_master.log" )

        ::File.open("#{ log_loc }/#{ name }-shorewall-#{ timestamp }.html", "w") { |f| f.write(out.join("\n").scrub_pretty_text.gsub('[sudo] password for deploy: ', '')) } unless options['no_logs']

        sudo_execute(passwords[ip_address], :rm, '-f', '/tmp/syslog_master.log')

        out.join("\n")
      end
    end
  end
end
