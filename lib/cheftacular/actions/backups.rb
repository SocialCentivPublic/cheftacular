
class Cheftacular
  class ActionDocumentation
    def backups
      @config['documentation']['action'][__method__] ||= {}
      @config['documentation']['action'][__method__]['long_description'] = [
        "`cft backups [activate|deactivate|fetch|load|restore]` this command " +
        "sets the fetch_backups and restore_backups flags in your config data bag for an environment. " +
        "These can be used to give application developers a way to trigger / untrigger restores in an environment",
      
        [
          "    1. `activate` will turn on automated backup running (turns on the flag for the env in the config bag).",

          "    2. `deactivate` will turn off automated backup running.",

          "    3. `fetch` will fetch the latest backup and drop it onto your machine. This argument accepts the --save-to-file LOCATION flag.",

          "    4. `load` will fetch the latest backup from the production primary **if it doesn't already exist on " +
          "the server** and run the _backup loading command_ to load this backup into the env.",

          "    5. `restore` will simply just run the _backup loading command_ to load the latest backup onto the server. This " +
          "command is REPOSITORY SENSITIVE, to restore a repo other than default, you must use the -R REPOSITORY flag.",

          "    6. `status` will display the current state of the backups",

          "    6. By default, the backups command will use the context of your current environment to trigger backup related commands."
        ]
      ]

      @config['documentation']['action'][__method__]['short_description'] = 'Runs various backup commands on your current environment'
    end
  end

  class Action
    def backups command=''
      command = ARGV[1] if command.blank?

      raise "Unsupported command (#{ command }) for cft backups" unless command =~ /activate|deactivate|fetch|load|restore|status/

      self.send("backups_#{ command }")
    end

    private

    def backups_activate restore_backup=true, fetch_backup=true
      backups_toggle_setting(restore_backup, fetch_backup)
    end

    def backups_deactivate restore_backup=false, fetch_backup=false
      backups_toggle_setting(restore_backup, fetch_backup)
    end

    def backups_load status_hash={}
      target_db_primary, nodes, status_hash, backup_master_local_ip = backups_get_status_hash_from_backupmaster

      return false unless status_hash['latest_backup']['file_check']

      options, locs, ridley, logs_bag_hash, pass_bag_hash, bundle_command, cheftacular, passwords = @config['helper'].set_local_instance_vars

      on ( target_db_primary.map { |n| @config['cheftacular']['deploy_user'] + "@" + n.public_ipaddress } ) do |host|
        n = get_node_from_address(nodes, host.hostname)

        puts("Beginning db_backup_fetch for #{ n.name } (#{ n.public_ipaddress }) for env #{ options['env'] }") unless options['quiet']

        start_db_backup_fetch( n.name, n.public_ipaddress, options, locs, cheftacular, passwords, backup_master_local_ip, status_hash['latest_backup'])
      end

      backups_restore
    end

    def backups_restore
      backup_mode = case @config['getter'].get_current_database
                    when 'postgresql' then 'pg'
                    when 'mongodb'    then 'mongo'
                    end

      target_db_primary, nodes = @config['getter'].get_db_primary_node_and_nodes
      applications_as_string   = @config['getter'].get_repo_names_for_repositories([{ database: @config['getter'].get_current_database }, { restore_backup_file_name: 'NOT NIL' , ignore_val: true}]).keys.join(',')
      env_db_pass              = @config[@options['env']]['chef_passwords_bag_hash']["#{ backup_mode }_pass"]
      env_db_user              = @config['getter'].get_current_repo_config['application_database_user']
      env_db_mode              = @config['getter'].get_current_database

      options, locs, ridley, logs_bag_hash, pass_bag_hash, bundle_command, cheftacular, passwords = @config['helper'].set_local_instance_vars

      ruby_command = @config['ruby_command']

      on ( target_db_primary.map { |n| @config['cheftacular']['deploy_user'] + "@" + n.public_ipaddress } ) do |host|
        n = get_node_from_address(nodes, host.hostname)

        puts("Beginning db_backup_run for #{ n.name } (#{ n.public_ipaddress }) for env #{ options['env'] }") unless options['quiet']

        start_db_backup_restore( n.name, n.public_ipaddress, options, locs, cheftacular, passwords, applications_as_string, env_db_pass, ruby_command, env_db_mode, env_db_user )
      end
    end

    def backups_fetch
      target_db_primary, nodes, status_hash, backup_master_local_ip = backups_get_status_hash_from_backupmaster(__method__.to_s)

      full_backup_dir  = File.join(@config['cheftacular']['backup_config']['db_primary_backup_path'], status_hash['latest_backup']['file_dir'])
      full_backup_path = File.join(full_backup_dir, status_hash['latest_backup']['filename'])

      file_scp_execute(target_db_primary, 'scp', full_backup_dir, status_hash['latest_backup']['filename'])
    end

    def backups_status
      backups_check_current_status
    end

    def backups_toggle_setting restore_backup, fetch_backup
      backups_check_current_status

      puts "For #{ @options['env'] } (sub-env: #{ @options['sub_env'] }) fetch backups is now set to " +
        "#{ fetch_backup ? 'on' : 'off' } and restoring backups is now set to #{ restore_backup ? 'on' : 'off' }"

      @config[@options['env']]['config_bag_hash'][@options['sub_env']]['fetch_backups']   = fetch_backup
      @config[@options['env']]['config_bag_hash'][@options['sub_env']]['restore_backups'] = restore_backup

      @config['ChefDataBag'].save_config_bag

      puts "Triggering deploy on databases to refresh backup setting..."

      @options['role'] = 'db_primary'

      @config['action'].deploy
    end

    def backups_check_current_status
      initial_fetch_backup   = @config[@options['env']]['config_bag_hash'][@options['sub_env']]['fetch_backups']
      initial_restore_backup = @config[@options['env']]['config_bag_hash'][@options['sub_env']]['restore_backups']

      puts "For #{ @options['env'] } (sub-env: #{ @options['sub_env'] }) fetch backups is currently set to " +
        "#{ initial_fetch_backup ? 'on' : 'off' } and restoring backups is currently set to #{ initial_restore_backup ? 'on' : 'off' }"
    end

    def backups_get_status_hash_from_backupmaster mode='backups_load', status_hash={}
      backup_env = @config['cheftacular']['backup_config']['global_backup_environ']

      if backup_env != @options['env']
        @config['initializer'].initialize_data_bags_for_environment(backup_env, false, ['addresses', 'server_passwords', 'logs'])
        @config['initializer'].initialize_passwords backup_env
      end

      if mode == 'backups_load'
        old_role, old_env = @options['role'], @options['env']

        @options['role'] = @config['cheftacular']['backup_config']['global_backup_role_name']
        @options['env']  = backup_env

        puts "Deploying to backup master to force refresh of the ssh keys..." 
        @config['action'].deploy

        @options['role'] = old_role
        @options['env']  = old_env
      end

      target_db_primary, nodes = @config['getter'].get_db_primary_node_and_nodes

      args_config = [
        { unless: "role[#{ @config['cheftacular']['backup_config']['global_backup_role_name'] }]" },
        { if: { not_env: backup_env } }
      ]

      backup_master          = @config['parser'].exclude_nodes( nodes, args_config, true)
      backup_master_local_ip = @config['getter'].get_address_hash(backup_master.first.name, true)[backup_master.first.name]['priv']

      options, locs, ridley, logs_bag_hash, pass_bag_hash, bundle_command, cheftacular, passwords = @config['helper'].set_local_instance_vars

      on ( backup_master.map { |n| @config['cheftacular']['deploy_user'] + "@" + n.public_ipaddress } ) do |host|
        n = get_node_from_address(nodes, host.hostname)

        puts("Beginning latest db_fetch_and_check for #{ n.name } (#{ n.public_ipaddress }) for env #{ backup_env }") unless options['quiet']

        status_hash['latest_backup'] = start_db_check_and_fetch( n.name, n.public_ipaddress, options, locs, cheftacular, passwords)
      end

      return [nil, nil, {}] unless status_hash['latest_backup']['file_check']

      [target_db_primary, nodes, status_hash, backup_master_local_ip]
    end
  end
end

module SSHKit
  module Backend
    class Netssh
      def start_db_check_and_fetch name, ip_address, options, locs, cheftacular, passwords, out=[], return_hash={ 'file_check' => false }
        base_dir = cheftacular['backup_config']['global_backup_path']

        if !sudo_test( passwords[ip_address], base_dir ) #true if dir exists
          puts "#{ name } (#{ ip_address }) cannot run #{ __method__ } as there is no directory at #{ base_dir }!"

          return return_hash
        end

        target_dir = case cheftacular['backup_filesystem']
                     when 'backup_gem'
                       backup_gem_dir_sort passwords[ip_address], cheftacular, base_dir
                     when 'raw'
                       File.join( base_dir, sudo_capture( passwords[ip_address], :ls, base_dir ).split(' ').last )
                     else
                       raise "#{ __method__ } does not currently support the #{ cheftacular['backup_filesystem'] } backup strategy at this time"
                     end

        return_hash['file_check'] = true
        return_hash['filename']   = [target_dir].flatten.last
        return_hash['file_dir']   = case cheftacular['backup_filesystem']
                                    when 'backup_gem' then target_dir.first
                                    when 'raw'        then base_dir
                                    end

        return_hash['backup_master_path'] = case cheftacular['backup_filesystem']
                                            when 'backup_gem' then File.join(base_dir, return_hash['file_dir'], return_hash['filename'])
                                            when 'raw'        then File.join(base_dir, return_hash['filename'])
                                            end

        return_hash
      end

      def start_db_backup_fetch name, ip_address, options, locs, cheftacular, passwords, backup_master_local_ip, backup_hash, out=[]
        full_backup_dir  = File.join(cheftacular['backup_config']['db_primary_backup_path'], backup_hash['file_dir'])
        full_backup_path = File.join(full_backup_dir, backup_hash['filename'])

        if sudo_test( passwords[ip_address], full_backup_path ) #true if dir exists
          puts "#{ name } (#{ ip_address }) already has the backup at #{ full_backup_path }, skipping #{ __method__ }..."

          return true
        end

        sudo_execute( passwords[ip_address], :mkdir, '-p', full_backup_dir )

        sudo_execute( passwords[ip_address], :chown, "#{ cheftacular['deploy_user'] }:#{ cheftacular['deploy_user'] }", full_backup_dir )

        sudo_execute( passwords[ip_address], :chmod, cheftacular['backup_config']['backup_dir_mode'], full_backup_dir )

        execute( :scp, '-oStrictHostKeyChecking=no', "#{ cheftacular['deploy_user'] }@#{ backup_master_local_ip }:#{ backup_hash['backup_master_path'] }", full_backup_path )

        puts "Finished transferring #{ full_backup_path } to #{ name }(#{ ip_address })..."
      end

      def start_db_backup_restore name, ip_address, options, locs, cheftacular, passwords, applications_as_string, env_db_pass, ruby_command, env_db_mode, env_db_user, out=''
        log_loc, timestamp = set_log_loc_and_timestamp(locs)

        puts "Beginning backup run on #{ name } (#{ ip_address }), this command may take a while to complete..."

        case cheftacular['backup_filesystem']
        when 'backup_gem'
          command = cheftacular['backup_config']['backup_load_command']
          command = command.gsub('ENVIRONMENT', options['env']).gsub('APPLICATIONS', applications_as_string).gsub('DB_PASS', env_db_pass)
          command = command.gsub('RUBY_COMMAND', ruby_command ).gsub('MODE', env_db_mode).gsub('DATABASE_USER', env_db_user)

          out << sudo_capture( passwords[ip_address], command )
        when 'raw'
        end

        ::File.open("#{ log_loc }/#{ name }-backup-restore-#{ timestamp }.txt", "w") { |f| f.write(out.scrub_pretty_text) } unless options['no_logs']

        puts "Finished executing backup command on #{ name } (#{ ip_address }). Wrote logs to #{ log_loc }/#{ name }-backup-restore-#{ timestamp }.txt"
      end

      def backup_gem_dir_sort password, cheftacular, base_dir
        timestamp_dirs, check_dirs, target_dir = [], [], ''

        dirs = sudo_capture( password, :ls, base_dir )

        dirs.split(' ').each do |timestamp_dir|
          next if timestamp_dir == '.' || timestamp_dir == '..'

          timestamp_dirs << timestamp_dir
        end

        timestamp_dirs.each do |dir|
          if check_dirs.empty?
            check_dirs << dir
            target_dir  = dir
          else
            check_dirs.each do |cdir|
              target_dir = dir if Date.parse(dir) >= Date.parse(target_dir)
            end
          end
        end

        target_file = sudo_capture( password, :ls, File.join(base_dir, target_dir) ).split(' ').last

        [ target_dir, target_file ]
      end
    end
  end
end
