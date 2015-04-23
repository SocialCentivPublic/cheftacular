
class Cheftacular
  module RemoteHelpers
    def set_log_loc_and_timestamp
      @dummy_sshkit.set_log_loc_and_timestamp( @locs )
    end

    def start_tail_log ip_address, run_list
      true_env = @config['dummy_sshkit'].get_true_environment run_list, @config['cheftacular']['run_list_environments'], @options['env']

      #special servers should be listed first as most of them will have web role
      log_loc = case
                when run_list.include?('role[sensu_server]')
                  "/var/log/sensu/sensu-server.log"
                when run_list.include?('role[graphite_server]')
                  "/var/log/carbon-cache/current"
                when run_list.include?('role[web]') && !run_list.include?('nodejs')
                  "/var/www/vhosts/#{ get_codebase_from_role_name( @options['role']) }/current/log/#{ true_env }.log"
                when run_list.include?('role[worker]') || run_list.include?('nodejs')
                  "/var/log/syslog"
                else
                  puts "This gem is not currently configured to handle tailing this case"
                  return 0
                end

      
      `ssh -oStrictHostKeyChecking=no -tt deploy@#{ ip_address } "#{ sudo(ip_address) } tail -f #{ log_loc }" > /dev/tty`
    end
  end
end
