class Cheftacular
  class StatelessActionDocumentation
    def file
      @config['documentation']['stateless_action'] <<  [
        "`cft file NODE_NAME LOCATION_ALIAS MODE FILE_NAME` interacts with a file on the remote server",

        [
          "    1. `LOCATION_ALIAS` will be parsed as a path if it has backslash characters. Otherwise it will be parsed from your " +
          "location_aliases hash in your cheftacular.yml",

          "    2. `FILE_NAME` is the actual name (can also be additional path to the file) of the file to be interacted with. If no " +
          "value is passed or the file does not exist in the LOCATION_ALIAS, the command will return the entries in LOCATION_ALIAS",

          "        1. *NOTE! If you plan to use FILE_NAME as a path, do prepend the path with a / character!*",

          "    3. `MODE` can be `cat|display|edit|fetch|list|scp|tail|tail-f`.",

          "        1. The default mode is display, this is what will be run at LOCATION_ALIAS for FILE_NAME if no MODE is passed.",

          "        2. `cat|display` will attempt to display the FILE_NAME listed to your terminal.",

          "        3. `edit:TEXT_EDITOR` will attempt to edit the file with the TEXT_EDITOR listed. NOTE! This editor must be installed " +
          "on the node you're accessing. If the editor is not present via a `which` command, the cft file command will say so.",

          "        4. `fetch|scp` will attempt to fetch the FILE_NAME listed via SCP. This file is saved to #{ @config['locs']['app-tmp'] } " + 
          "(based on your directory structure) under the same FILE_NAME as the remote file.",

          "            1. The #{ @config['cheftacular']['deploy_user'] } must have access to said file without sudo!",

          "        5. `list` the default behavior if the file does not exist. Otherwise must be manually called.",

          "        6. `tail:NUMBER_OF_LINES` tails the file for the last `NUMBER_OF_LINES` lines, defaults to 500.",

          "        7. `tail-f` enables continuous output of the file.",

          "    4. `--save-to-file FILE_NAME option will save the output of `cat|display|tail` to a file on your local system instead of " +
          "displaying the file to your terminal window.",

          "        1. `--save-to-file FILE_PATH` can also be used in the `fetch` context to specify where exactly to save the file and " +
          "what to name it as."
        ]
      ]

      @config['documentation']['application'] << @config['documentation']['stateless_action'].last
    end
  end

  class StatelessAction
    def file location='', file_name='',mode=''
      @options['node_name'] = ARGV[1] unless @options['node_name']
      location              = ARGV[2] if location.blank?
      mode                  = ARGV[3] if mode.blank?
      file_name             = ARGV[4] if file_name.blank?

      nodes = @config['error'].is_valid_node_name_option?

      mode = 'display' if mode.nil?
      mode = 'list'    if file_name.nil? || file_name.blank?

      interaction_mode = case mode.split(':').first
                         when 'cat'       then 'sshkit'
                         when 'display'   then 'sshkit'
                         when 'edit'      then 'ssh'
                         when /fetch|scp/ then 'scp'
                         when 'list'      then 'sshkit'
                         when 'tail'      then 'sshkit'
                         when 'tail-f'    then 'ssh'
                         else                  raise "Unsupported Mode for cft file: #{ mode }, "
                         end

      
      location = @config['parser'].parse_location_alias(location)
      command  = @config['parser'].parse_mode_into_command(mode)

      nodes = @config['parser'].exclude_nodes( nodes, [{ unless: { env: @options['env'] }}], true )

      case interaction_mode
      when 'sshkit' then file_sshkit_execute(nodes, command, location, file_name)
      when 'ssh'    then file_ssh_execute(nodes, mode, command, location, file_name)
      when 'scp'    then file_scp_execute(nodes, command, location, file_name)
      end
    end

    private

    def file_sshkit_execute nodes, command, location, file_name, exit_status=true
      options, locs, ridley, logs_bag_hash, pass_bag_hash, bundle_command, cheftacular, passwords = @config['helper'].set_local_instance_vars

      on ( nodes.map { |n| @config['cheftacular']['deploy_user'] + "@" + n.public_ipaddress } ) do |host|
        n = get_node_from_address(nodes, host.hostname)

        puts("Beginning run of \"file #{ command }\" for #{ n.name } (#{ n.public_ipaddress })") if command != 'check_existence' || options['quiet']

        exit_status = start_command_run( n.name, n.public_ipaddress, options, locs, passwords, cheftacular, command, location, file_name)
      end

      exit_status
    end

    def file_ssh_execute nodes, mode, command, location, file_name
      unless file_sshkit_execute( nodes, 'check_existence', location, file_name)
        puts "Not executing #{ command } due to failing exit status..."

        return false
      end

      nodes.each do |n|
        target_loc = "#{ location }/#{ file_name }"
        puts("Beginning #{ command } run on #{ target_loc } for #{ n.name } (#{ n.public_ipaddress })") unless @options['quiet']

        sudo_mode = "#{ @config['helper'].sudo(n.public_ipaddress) }"
        sudo_mode = '' if mode.split(':').first == 'edit'

        `ssh -oStrictHostKeyChecking=no -tt #{ @config['cheftacular']['deploy_user'] }@#{ n.public_ipaddress } "#{ sudo_mode } #{ command } #{ target_loc }" > /dev/tty`
      end
    end

    def file_scp_execute nodes, command, location, file_name
      unless file_sshkit_execute( nodes, 'check_existence', location, file_name)
        puts "Not executing #{ command } due to failing exit status..."

        return false
      end

      nodes.each do |n|
        target_loc = "#{ location }/#{ file_name }"
        puts("Beginning #{ command } run on #{ target_loc } for #{ n.name } (#{ n.public_ipaddress })") unless @options['quiet']

        download_location = @options['save_to_file'] ? @options['save_to_file'] : "#{ @config['locs']['chef-log'] }/#{ file_name.split('/').last }"

        `scp -oStrictHostKeyChecking=no #{ @config['cheftacular']['deploy_user'] }@#{ n.public_ipaddress }:#{ location }/#{ file_name } #{ download_location } > /dev/tty`

        puts "Finished downloading #{ file_name } to #{ download_location }!"
      end
    end
  end
end

module SSHKit
  module Backend
    class Netssh
      def start_command_run name, ip_address, options, locs, passwords, cheftacular, command, location, file_name, out="", exit_status=true
        log_loc, timestamp = set_log_loc_and_timestamp(locs)
        run_list_command   = command == 'list'
        target_loc = "#{ location }/#{ file_name }"

        if !sudo_test( passwords[ip_address], location ) #true if file exists
          puts "#{ name } (#{ ip_address }) cannot run #{ command } as there is no directory at #{ location }!"

          return false
        end

        if !run_list_command && !sudo_test( passwords[ip_address], target_loc ) #true if file exists
          puts "#{ name } (#{ ip_address }) cannot run #{ command } as there is no file at #{ location }/#{ file_name }! Running list instead..."

          exit_status = false

          run_list_command = true
        end

        return exit_status if command == 'check_existence'

        if run_list_command
          out << sudo_capture( passwords[ip_address], :ls, '-al', location )
        else
          puts "Running #{ command } on #{ target_loc }"
          out << sudo_capture( passwords[ip_address], command, target_loc)
        end

        if options['save_to_file']
          out_location = "#{ log_loc }/#{ options['save_to_file'] }"

          puts "Saving output of file at #{ out_location } }..."

          ::File.open(out_location, "w") { |f| f.write(out) }
        end

        puts out.scrub_pretty_text unless options['save_to_file']

        puts("Succeeded run of \"#{ command }\" for #{ name } (#{ ip_address })") unless run_list_command

        exit_status
      end
    end
  end
end
