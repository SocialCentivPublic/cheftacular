
class Cheftacular
  class StatelessActionDocumentation
    def backups
      @config['documentation']['stateless_action'] <<  [
        "`cft backup [activate|deactivate]` this command " +
        "sets the fetch_backups and restore_backups flags in your config data bag for an environment. " +
        "These can be used to give application developers a way to trigger / untrigger restores in an environment"
      ]

      @config['documentation']['application'] << @config['documentation']['stateless_action'].last
    end
  end

  class StatelessAction
    def backups force_fetch_and_restore=false
      fetch_backup   = @config[@options['env']]['config_bag_hash'][@options['sub_env']]['fetch_backups']
      restore_backup = @config[@options['env']]['config_bag_hash'][@options['sub_env']]['restore_backups']

      puts "For #{ @options['env'] } (sub-env: #{ @options['sub_env'] }) fetch backups was set to #{ fetch_backup ? 'on' : 'off' } and restoring backups was set to #{ restore_backup ? 'on' : 'off' }"

      case ARGV[1]
      when 'activate'   then restore_backup, fetch_backup = true, true
      when 'deactivate' then restore_backup, fetch_backup = false, false
      end

      puts "For #{ @options['env'] } (sub-env: #{ @options['sub_env'] }) fetch backups is now set to #{ fetch_backup ? 'on' : 'off' } and restoring backups is now set to #{ restore_backup ? 'on' : 'off' }"

      @config[@options['env']]['config_bag_hash'][@options['sub_env']]['fetch_backups']   = fetch_backup
      @config[@options['env']]['config_bag_hash'][@options['sub_env']]['restore_backups'] = restore_backup

      @config['ChefDataBag'].save_config_bag

      if force_fetch_and_restore
        nodes = @config['getter'].get_true_node_objects true

        db_primary_nodes = @config['parser'].exclude_nodes( nodes, [{ unless: 'role[db_primary]' }, { if: { not_env: 'production' } }])

        backup_slave_local_ip = @config['cheftacular']['backup_server']

        if backup_slave_local_ip == 'first_production_slave'
          backup_slave = @config['parser'].exclude_nodes( nodes, [{ unless: 'role[db_slave]' }, { if: { not_env: 'production' } }], true)

          backup_slave_local_ip = @config['getter'].get_address_hash(backup_slave.first.hostname)['priv']
        end

        options, locs, ridley, logs_bag_hash, pass_bag_hash, bundle_command, cheftacular, passwords = set_local_instance_vars

        on ( db_primary_nodes.map { |n| @config['cheftacular']['deploy_user'] + "@" + n.public_ipaddress } ) do |host|
          n = get_node_from_address(nodes, host.hostname)

          puts("Beginning db fetch_and_restore for #{ n.name } (#{ n.public_ipaddress }) for env #{ options['env'] }") unless options['quiet']

          start_db_fetch_and_restore( n.name, n.public_ipaddress, options, locs, cheftacular, passwords, backup_slave_local_ip)
        end

        @config['action'].migrate
      else
        puts "Triggering deploy on databases to refresh backup setting..."

        @options['role'] = 'db_primary'

        @config['action'].deploy
      end
    end
  end
end

module SSHKit
  module Backend
    class Netssh
      def start_db_fetch_and_restore name, ip_address, options, locs, cheftacular, passwords, global_backup_ip, out=[]
        log_loc, timestamp = set_log_loc_and_timestamp(locs)

        puts("Generating pg_restore log file for #{ name } (#{ ip_address }) at #{ log_loc }/#{ name }-fetch-and-restore-#{ timestamp }.txt") unless options['quiet']

        cheftacular['db_primary_backup_database_stacks'].each do |target_database_stack|
          compile_database_backups_hash(cheftacular, target_database_stack, global_backup_ip).each_pair do |app_name, app_hash|

            out << sudo_capture( passwords[ip_address], 'scp', "#{ cheftacular['deploy_user'] }@#{ app_hash['backup_server'] }:#{ location }", backup_dir )

            puts(out.last) if options['output'] || options['verbose']

            commands = [
              "pg_restore --verbose --clean --no-acl --no-owner -j 4 -h localhost -U #{ cheftacular['deploy_user'] } -d #{ app_hash['repo_name'] }_#{ options['env'] } #{ app_hash['restore_backup_file_name'] }",
              "service postgresql restart"
            ]

            commands.each do |command|
              out << sudo_capture( passwords[ip_address], command )

              puts(out.last) if options['output'] || options['verbose']
            end
          end
        end

        #TODO fetch and restore other database types

        ::File.open("#{ log_loc }/#{ name }-fetch-and-restore-#{ timestamp }.txt", "w") { |f| f.write(out.join("\n").scrub_pretty_text) } unless options['no_logs']

        puts "Succeeded fetch and restore of #{ name } (#{ ip_address })"

        [out.join("\n"), timestamp]
      end

      def compile_database_backups_hash cheftacular, target_database_stack, global_backup_ip, ret={}
        cheftacular['repositories'].each_pair do |app_name, app_hash|
          ret[app_name] = app_hash if app_hash['restore_backup_file_name'] && app_hash['database'] == target_database_stack
          ret[app_name]['backup_server'] = global_backup_ip unless ret[app_name]['backup_server']
        end

        ret
      end
    end
  end
end
