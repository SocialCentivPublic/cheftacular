module SSHKit
  module Backend
    class Netssh
      def start_task name, ip_address, run_list, command, options, locs, cheftacular, out=""
        log_loc, timestamp = set_log_loc_and_timestamp(locs)
        true_env = get_true_environment run_list, cheftacular['run_list_environments'][options['env']], options['env']

        puts "Running #{ command } for #{ name } (#{ ip_address }) (Run with with --debug to generate a log as well)"

        target_loc = "#{ cheftacular['base_file_path'] }/#{ options['repository'] }/current"

        if test( target_loc )
          puts "#{ name } (#{ ip_address }) cannot run #{ command } as there is no directory at #{ target_loc }!"

          return ['', timestamp]
        end

        capture_args = ["RAILS_ENV=#{ true_env }"]
        capture_args << command.split(' ')

        within target_loc do
          out << capture( *capture_args.flatten )
        end

        ::File.open("#{ log_loc }/#{ name }-task-#{ timestamp }.txt", "w") {|f| f.write(out.scrub_pretty_text) } if options['debug']
        
        puts out

        if out.empty? || ( cheftacular['repositories'][options['role']].has_key?('not_a_migration_message') && out == cheftacular['repositories'][options['role']]['not_a_migration_message'] )
          puts("Nothing to migrate for #{ options['role'] }...")
        end

        [out, timestamp, 0] #return out to send to logs_bag
      rescue SSHKit::Command::Failed => e
        puts "@@@@@CRITICAL! #{ command } failed for #{ name } (#{ ip_address })! Please check your #{ log_loc }/failed-deploy for the logs!@@@@@"

        puts(e.message)

        ::File.open("#{ log_loc }/failed-deploy/#{ name }-task-#{ timestamp }.txt", "w") { |f| f.write(e.message.scrub_pretty_text) }

        [e.message, timestamp, 1]
      end
    end
  end
end
