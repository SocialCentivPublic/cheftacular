module SSHKit
  module Backend
    class Netssh
      def start_log_role_map name, ip_address, target_log_loc, options, locs, cheftacular, passwords, out=""
        log_loc, timestamp  = set_log_loc_and_timestamp(locs)
        log_cmnd, log_lines = get_log_command_and_lines(options)

        if !test("[ -e #{ target_log_loc }]") #true if file exists
          puts "#{ name } (#{ ip_address }) does not have a log file for #{ options['env'] } at the moment..."

        else
          puts "Fetching log file(s) for #{ name } (#{ ip_address }). Outputting to #{ log_loc }/#{ name }-#{ options['role'] }-log-#{ timestamp }.txt"

          target_log_loc.split(',').each do |parsed_log_loc|
            parsed_log_loc = parsed_log_loc.gsub('|current_repo_location|', "#{ cheftacular['base_file_path'] }/#{ options['repository'] }/current")
            if log_lines.nil?
              out << sudo_capture(passwords[ip_address], log_cmnd.to_sym, parsed_log_loc)

            else
              out << sudo_capture(passwords[ip_address], log_cmnd.to_sym, log_lines, parsed_log_loc)
            end
          end

          ::File.open("#{ log_loc }/#{ name }-#{ options['role'] }-log-#{ timestamp }.txt", "w") { |f| f.write(out.scrub_pretty_text) } unless options['no_logs']
        end
      end

      def start_log_fetch_ruby_on_rails name, ip_address, run_list, options, locs, cheftacular, passwords, out=""
        log_loc, timestamp  = set_log_loc_and_timestamp(locs)
        true_env            = get_true_environment run_list, cheftacular['run_list_environments'], options['env']
        app_log_loc         = "#{ cheftacular['base_file_path'] }/#{ options['repository'] }/current/log"
        log_cmnd, log_lines = get_log_command_and_lines(options)

        if !test("[ -e /#{ app_log_loc }/#{ true_env }.log ]") #true if file exists
          puts "#{ name } (#{ ip_address }) does not have a log file for #{ true_env } at the moment..."

        else

          puts "Fetching log file(s) for #{ name } (#{ ip_address }). Outputting to #{ log_loc }/#{ name }-applog-#{ timestamp }.txt"

          within app_log_loc do
            if log_lines.nil?
              out << capture(log_cmnd.to_sym, "#{ true_env }.log")

            else
              out << capture(log_cmnd.to_sym, log_lines, "#{ true_env }.log")
            end
          end

          #To create the file locally you must namespace like this
          ::File.open("#{ log_loc }/#{ name }-applog-#{ timestamp }.txt", "w") { |f| f.write(out.scrub_pretty_text) } unless options['no_logs']
        end

        out << start_log_fetch_nginx(name, log_loc, log_cmnd, timestamp, options, out) if run_list.include?('role[web]') && options['get_nginx_logs']
        
        out << start_log_role_map(name, ip_address, get_role_map(cheftacular, get_worker_role(cheftacular))['log_location'], log_cmnd, app_log_loc, timestamp, options) if run_list.include?("role[#{ get_worker_role(cheftacular) }]")

        puts(out) if options['verbose']
      end

      def start_log_fetch_nginx name, log_loc, log_cmnd, timestamp, options, out=""
        out = "" unless options['no_logs']

        nginx_log_loc = "/var/log/nginx/#{ options['repository'] }_access.log"

        puts "Fetching nginx log file... Outputting to #{ log_loc }/#{ name }-nginxlog-#{ timestamp }.txt "

        if log_lines.nil?
          out << capture(log_cmnd.to_sym, nginx_log_loc)

        else 
          out << capture(log_cmnd.to_sym, log_lines, nginx_log_loc)
        end

        ::File.open("#{ log_loc }/#{ name }-nginxlog-#{ timestamp }.txt", "w") { |f| f.write(out.scrub_pretty_text) } unless options['no_logs']

        out
      end

      private

      def get_log_command_and_lines options
        log_cmnd = options['get_full_logs'] ? 'cat' : 'tail'

        log_lines = options['get_full_logs'] ? nil : "-" + ( options['get_log_lines'] ? options['get_log_lines'] : "500" )

        [log_cmnd, log_lines]
      end
    end
  end
end