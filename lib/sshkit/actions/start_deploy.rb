module SSHKit
  module Backend
    class Netssh
      def start_deploy name, ip_address, options, locs, passwords, out=""
        log_loc, timestamp = set_log_loc_and_timestamp(locs)

        puts "Generating log file for #{ name } (#{ ip_address }) at #{ log_loc }/#{ name }-deploy-#{ timestamp }.txt"

        capture_args = [ "chef-client" ]
        capture_args << [ '-l', 'debug' ] if options['debug']
        #capture_args << [ '>', '/dev/tty']

        out << sudo_capture( passwords[ip_address], *capture_args.flatten )

        ::File.open("#{ log_loc }/#{ name }-deploy-#{ timestamp }.txt", "w") { |f| f.write(out.scrub_pretty_text) } unless options['no_logs']

        puts(out) if options['output'] || options['verbose']

        puts "Succeeded deploy of #{ name } (#{ ip_address }) on role #{ options['role'] }"

        [out, timestamp] #return out to send to logs_bag
      end
    end
  end
end
