
class Cheftacular
  class StatelessActionDocumentation
    def backups
      @config['documentation']['stateless_action'] <<  [
        "`cft backups [activate|deactivate|load|run]` this command " +
        "sets the fetch_backups and restore_backups flags in your config data bag for an environment. " +
        "These can be used to give application developers a way to trigger / untrigger restores in an environment",
      
        [
          "    1. `activate` will turn on automated backup running (turns on the flag for the env in the config bag).",

          "    2. `deactivate` will turn off automated backup running.",

          "    3. `load` will fetch the latest backup from the production primary **if it doesn't already exist on " +
          "the server** and run the _backup loading command_ to load this backup into the env.",

          "    4. `run` will simply just run the _backup loading command_ to load the latest backup onto the server."
        ]
      ]

      @config['documentation']['application'] << @config['documentation']['stateless_action'].last
    end
  end

  class StatelessAction
    def backups command=''
      command = ARGV[1] if command.blank?

      raise "Unsupported command (#{ command }) for cft backups" unless command =~ /activate|deactivate|load|run/

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
      old_role, old_env, backup_env = @options['role'], @options['env'], @config['cheftacular']['backup_config']['global_backup_environ']

      if backup_env != @options['env']
        @config['initializer'].initialize_data_bags_for_environment(backup_env, false, ['addresses', 'server_passwords'])
        @config['initializer'].initialize_passwords backup_env
      end

      @options['role'] = @config['cheftacular']['backup_config']['global_backup_role_name']
      @options['env']  = backup_env

      puts "Deploying to backup master to force refresh of the ssh keys..." 
      #@config['action'].deploy

      @options['role'] = old_role
      @options['env']  = old_env

      target_db_primary = @config['getter'].get_db_primary_node

      args_config = [
        { unless: "role[#{ @config['cheftacular']['backup_config']['global_backup_role_name'] }]" },
        { if: { not_env: backup_env } }
      ]

      backup_master          = @config['parser'].exclude_nodes( nodes, args_config, true)
      backup_master_local_ip = @config['getter'].get_address_hash(backup_master.first.name)['priv']

      options, locs, ridley, logs_bag_hash, pass_bag_hash, bundle_command, cheftacular, passwords = @config['helper'].set_local_instance_vars

      on ( backup_master.map { |n| @config['cheftacular']['deploy_user'] + "@" + n.public_ipaddress } ) do |host|
        n = get_node_from_address(nodes, host.hostname)

        puts("Beginning latest db_fetch_and_check for #{ n.name } (#{ n.public_ipaddress }) for env #{ options['env'] }") unless options['quiet']

        status_hash['latest_backup'] = start_db_check_and_fetch( n.name, n.public_ipaddress, options, locs, cheftacular, passwords)
      end

      return false unless status_hash['latest_backup']['file_check']

      on ( target_db_primary.map { |n| @config['cheftacular']['deploy_user'] + "@" + n.public_ipaddress } ) do |host|
        n = get_node_from_address(nodes, host.hostname)

        puts("Beginning db_backup_fetch for #{ n.name } (#{ n.public_ipaddress }) for env #{ options['env'] }") unless options['quiet']

        start_db_backup_fetch( n.name, n.public_ipaddress, options, locs, cheftacular, passwords, backup_master_local_ip, status_hash['latest_backup'])
      end

      backups_run(nodes)
    end

    def backups_run
      target_db_primary      = @config['getter'].get_db_primary_node
      applications_as_string = @config['getter'].get_repo_names_for_repositories.keys.join(',')
      env_pg_pass            = @config[@options['env']]['chef_passwords_bag_hash']['pg_pass']

      options, locs, ridley, logs_bag_hash, pass_bag_hash, bundle_command, cheftacular, passwords = @config['helper'].set_local_instance_vars

      on ( target_db_primary.map { |n| @config['cheftacular']['deploy_user'] + "@" + n.public_ipaddress } ) do |host|
        n = get_node_from_address(nodes, host.hostname)

        puts("Beginning db_backup_run for #{ n.name } (#{ n.public_ipaddress }) for env #{ options['env'] }") unless options['quiet']

        start_db_backup_run( n.name, n.public_ipaddress, options, locs, cheftacular, passwords, applications_as_string, env_pg_pass )
      end
    end

    def backups_toggle_setting restore_backup, fetch_backup
      initial_fetch_backup   = @config[@options['env']]['config_bag_hash'][@options['sub_env']]['fetch_backups']
      initial_restore_backup = @config[@options['env']]['config_bag_hash'][@options['sub_env']]['restore_backups']

      puts "For #{ @options['env'] } (sub-env: #{ @options['sub_env'] }) fetch backups was set to " +
        "#{ initial_fetch_backup ? 'on' : 'off' } and restoring backups was set to #{ initial_restore_backup ? 'on' : 'off' }"

      puts "For #{ @options['env'] } (sub-env: #{ @options['sub_env'] }) fetch backups is now set to " +
        "#{ fetch_backup ? 'on' : 'off' } and restoring backups is now set to #{ restore_backup ? 'on' : 'off' }"

      @config[@options['env']]['config_bag_hash'][@options['sub_env']]['fetch_backups']   = fetch_backup
      @config[@options['env']]['config_bag_hash'][@options['sub_env']]['restore_backups'] = restore_backup

      @config['ChefDataBag'].save_config_bag

      puts "Triggering deploy on databases to refresh backup setting..."

      @options['role'] = 'db_primary'

      @config['action'].deploy
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
        return_hash['file_path']  = [target_dir].flatten.last
        return_hash['file_dir']   = case cheftacular['backup_filesystem']
                                    when 'backup_gem' then target_dir.first
                                    when 'raw'        then base_dir
                                    end

        return_hash
      end

      def start_db_backup_fetch name, ip_address, options, locs, cheftacular, passwords, backup_master_local_ip, backup_hash, out=[]
        if sudo_test( passwords[ip_address], backup_path ) #true if dir exists
          puts "#{ name } (#{ ip_address }) already has the backup at #{ backup_path }, skipping #{ __method__ }..."

          return true
        end

        sudo_execute( passwords[ip_address], :mkdir, '-p', backup_hash['file_dir'] )

        sudo_execute( passwords[ip_address], :chown, "#{ cheftacular['deploy_user'] }:#{ cheftacular['deploy_user'] }", backup_hash['file_dir'] )

        sudo_execute( passwords[ip_address], :chmod, cheftacular['backup_config']['backup_dir_mode'], backup_hash['file_dir'] )

        execute( :scp, "#{ cheftacular['deploy_user'] }@#{ backup_master_local_ip }:#{ backup_hash['file_path'] }", backup_hash['file_dir'] )

        puts "Finished transferring #{ backup_hash['file_path'] } to #{ name }(#{ ip_address })..."
      end

      def start_db_backup_run name, ip_address, options, locs, cheftacular, passwords, applications_as_string, env_pg_pass
        puts "Beginning backup run on #{ name } (#{ ip_address }), this command may take a while to complete..."
        case cheftacular['backup_filesystem']
        when 'backup_gem'
          #'ruby /root/backup_management.rb /mnt/postgresbackups/backups ENVIRONMENT APPLICATIONS PG_PASS > /root/restore.log 2>&1'
          command = cheftacular['backup_config']['backup_load_command']
          command = command.gsub('ENVIRONMENT', options['env']).gsub('APPLICATIONS', applications_as_string).gsub('PG_PASS', env_pg_pass)

          sudo_execute( passwords[ip_address], command )
        when 'raw'
        end

        puts "Finished executing backup command on #{ name } (#{ ip_address })"
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

        [ File.join(base_dir, target_dir), File.join( target_dir, target_file )]
      end
    end
  end
end
