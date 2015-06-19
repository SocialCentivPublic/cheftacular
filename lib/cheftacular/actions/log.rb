class Cheftacular
  class ActionDocumentation
    def log
      @config['documentation']['action'] <<  [
        "`cft log` this command will output the last 500 lines of logs " +
        "from every server set for CODEBASE (can be given additional args to specify) to the log directory",

        [
          "    1.  `--nginx` will fetch the nginx logs as well as the application logs",

          "    2.  `--full` will fetch the entirety of the logs (will fetch the entire nginx log too if `--nginx` is specified)",

          "    3. `--num INTEGER` will fetch the last INTEGER lines of logs",

          "        1. `-l|--lines INTEGER` does the exact same thing as `--num INTEGER`.",

          "    4. `--fetch-backup` If doing a pg_data log, this will fetch the latest logs from the pg_data log directory for each database."
        ]
      ]
    end
  end

  class Action
    def log
      nodes = @config['getter'].get_true_node_objects

      nodes = @config['parser'].exclude_nodes( nodes, [{ unless: "role[#{ @options['role'] }]" }] )

      #this must always precede on () calls so they have the instance variables they need
      options, locs, ridley, logs_bag_hash, pass_bag_hash, bundle_command, cheftacular, passwords = @config['helper'].set_local_instance_vars

      getter = @config['getter']

      on ( nodes.map { |n| @config['cheftacular']['deploy_user'] + "@" + n.public_ipaddress } ), in: :parallel do |host|
        n = get_node_from_address(nodes, host.hostname)

        puts("Beginning log fetch run for #{ n.name } (#{ n.public_ipaddress }) on role #{ options['role'] }") unless options['quiet']

        if has_run_list_in_role_map?(n.run_list, cheftacular['role_maps'])
          start_log_role_map( n.name, n.public_ipaddress, getter.get_current_role_map(n.run_list)['log_location'], options, locs, cheftacular, passwords)
        else
          self.send("start_log_fetch_#{ getter.get_current_stack }", n.name, n.public_ipaddress, n.run_list, options, locs, cheftacular, passwords)
        end
      end
    end
  end
end

module SSHKit
  module Backend
    class Netssh
      def start_log_role_map name, ip_address, target_log_loc, options, locs, cheftacular, passwords, out=""
        log_loc, timestamp  = set_log_loc_and_timestamp(locs)
        log_cmnd, log_lines = get_log_command_and_lines(options)

        
        puts "Fetching log file(s) for #{ name } (#{ ip_address }). Outputting to #{ log_loc }/rolelog with timestamp: #{ timestamp }"

        target_log_loc.split(',').each do |parsed_log_loc|
          parsed_log_loc = parsed_log_loc.gsub('|current_repo_location|', "#{ cheftacular['base_file_path'] }/#{ options['repository'] }/current")

          if parsed_log_loc != '/var/log/syslog' && !test("[ -e #{ parsed_log_loc }]") #true if file exists ()
            puts "#{ name } (#{ ip_address }) does not have a #{ parsed_log_loc } log file for #{ options['env'] } at the moment..."
          else
            if log_lines.nil?
              out << sudo_capture(passwords[ip_address], log_cmnd.to_sym, parsed_log_loc)

            else
              out << sudo_capture(passwords[ip_address], log_cmnd.to_sym, log_lines, parsed_log_loc)
            end

            ::File.open("#{ log_loc }/rolelog/#{ name }-#{ parsed_log_loc.split('/').last.split('.').first }-#{ timestamp }.txt", "w") { |f| f.write(out.scrub_pretty_text) } unless options['no_logs']
          end
        end
      end

      def start_log_fetch_ruby_on_rails name, ip_address, run_list, options, locs, cheftacular, passwords, out=""
        log_loc, timestamp  = set_log_loc_and_timestamp(locs)
        true_env            = get_true_environment run_list, cheftacular['run_list_environments'][options['env']], options['env']
        app_log_loc         = "#{ cheftacular['base_file_path'] }/#{ options['repository'] }/current/log"
        log_cmnd, log_lines = get_log_command_and_lines(options)

        if !test("[ -e /#{ app_log_loc }/#{ true_env }.log ]") #true if file exists
          puts "#{ name } (#{ ip_address }) does not have a log file for #{ true_env } at the moment..."

        else

          puts "Fetching log file(s) for #{ name } (#{ ip_address }). Outputting to #{ log_loc }/applog/#{ name }-applog-#{ timestamp }.txt"

          within app_log_loc do
            if log_lines.nil?
              out << capture(log_cmnd.to_sym, "#{ true_env }.log")

            else
              out << capture(log_cmnd.to_sym, log_lines, "#{ true_env }.log")
            end
          end

          #To create the file locally you must namespace like this
          ::File.open("#{ log_loc }/applog/#{ name }-applog-#{ timestamp }.txt", "w") { |f| f.write(out.scrub_pretty_text) } unless options['no_logs']
        end

        out << start_log_fetch_nginx(name, log_loc, log_cmnd, timestamp, options, out) if run_list.include?('role[web]') && options['get_nginx_logs']
        
        out << start_log_role_map(name, ip_address, get_role_map(cheftacular, get_worker_role(cheftacular))['log_location'], log_cmnd, app_log_loc, timestamp, options) if run_list.include?("role[#{ get_worker_role(cheftacular) }]")

        puts(out) if options['verbose']
      end

      def start_log_fetch_nginx name, log_loc, log_cmnd, timestamp, options, out=""
        out = "" unless options['no_logs']
        log_cmnd, log_lines = get_log_command_and_lines(options)

        nginx_log_loc = "/var/log/nginx/#{ options['repository'] }_access.log"

        puts "Fetching nginx log file... Outputting to #{ log_loc }/applog/#{ name }-nginxlog-#{ timestamp }.txt "

        if log_lines.nil?
          out << capture(log_cmnd.to_sym, nginx_log_loc)

        else 
          out << capture(log_cmnd.to_sym, log_lines, nginx_log_loc)
        end

        ::File.open("#{ log_loc }/applog/#{ name }-nginxlog-#{ timestamp }.txt", "w") { |f| f.write(out.scrub_pretty_text) } unless options['no_logs']

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
