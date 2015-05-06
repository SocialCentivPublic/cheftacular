class Cheftacular
  class StatelessActionDocumentation
    def get_shorewall_allowed_connections
      @config['documentation']['stateless_action'] <<  [
        "`cft get_shorewall_allowed_connections` command will query a single server and return all of its ACCEPT connections " +
        "from shorewall in it's syslog and return the results in a CSV format. Useful for tracking IP activity.",

        [
          "    1. This command will attempt to `dig` each ip address to give you the most likely culprit."
        ]
      ]
    end
  end

  class StatelessAction
    def get_shorewall_allowed_connections
      #TODO find and load syslog files from nodes!
      log_data << File.read(File.expand_path("#{ @locs['chef-log'] }/marketing_site_syslog_2.txt"))
      log_data << File.read(File.expand_path("#{ @locs['chef-log'] }/marketing_site_syslog_1.txt"))
      log_data << File.read(File.expand_path("#{ @locs['chef-log'] }/marketing_site_syslog.txt"))

      exit

      addresses = {}

      log_data.join("\n").scan(/^.*Shorewall:net2fw:ACCEPT.*SRC=([\d]+\.[\d]+\.[\d]+\.[\d]+) DST.*DPT=80.*$/).each do |ip_address|
        addresses[ip_address] ||= 0
        addresses[ip_address] += 1
      end

      final_addresses = {}
      check_count = 0
      addresses.each_pair do |address, count|
        domain = `dig +short -x #{ address[0] }`.chomp.split("\n").join('|')
        domain = domain[0..(domain.length-2)]

        domain = address[0] if domain.blank?

        final_addresses[domain] ||= {}
        final_addresses[domain]['addresses'] ||= []
        final_addresses[domain]['addresses'] <<  address[0] unless final_addresses[domain]['addresses'].include?(address[0])
        final_addresses[domain]['count']     =   count   unless final_addresses[domain].has_key?('count')
        final_addresses[domain]['count']     +=  count   if final_addresses[domain].has_key?('count')

        check_count += 1

        puts "Processed #{ check_count } addresses (#{ address[0] }):#{ domain }:#{ count }"
      end

      final_addresses = final_addresses.sort_by {|key, value_hash| value_hash['count']}.to_h

      final_addresses = Hash[final_addresses.to_a.reverse]

      ap(final_addresses)

      log_loc, timestamp = @config['helper'].set_log_loc_and_timestamp

      CSV.open(File.expand_path("#{ @locs['chef-log'] }/#{ @options['node_name'] }-shorewall-parse-#{ timestamp }.csv"), "wb") do |csv| 
        final_addresses.each_pair do |dns, info_hash|
          csv << [dns, info_hash['addresses'].join('|'), info_hash['count']]
        end
      end
    end
  end
end
