class Cheftacular
  class StatelessActionDocumentation
    def ubuntu_bootstrap_from_queue
      @config['documentation']['stateless_action'][__method__] ||= {}
      @config['documentation']['stateless_action'][__method__]['long_description'] = [
        "`cft ubuntu_bootstrap_from_queue` This command will bring a fresh server to a state " +
        "where chef-client can be run on it via `cft chef-bootstrap`. It should be noted that it is in "+
        "this step where a server's randomized deploy_user sudo password is generated."
      ]

      @config['documentation']['stateless_action'][__method__]['short_description'] = '[Not Directly Callable]'
    end
  end

  class StatelessAction
    def ubuntu_bootstrap_from_queue threads=[], execution_hash_array=[]
      raise "This action is not meant to be called directly!" if !@options['in_scaling'] && !@options['in_single_server_creation']

      @config['bootstrap_timestamp'] ||= Time.now.strftime("%Y%m%d%H%M%S")

      @config['queue_master'].generate_passwords_for_each_server_hash_in_queue

      execution_hash_array << compile_root_execute_hash
      execution_hash_array << compile_deploy_execute_hash
      execution_hash_array << compile_rvm_execute_hash           if @config['cheftacular']['install_rvm_on_boot']
      execution_hash_array << compile_install_rvm_sh_file_hashes if @config['cheftacular']['install_rvm_on_boot']
      execution_hash_array  = execution_hash_array.flatten(1)

      @config['server_creation_queue'].each do |server_hash|
        puts("#{ server_name_output(server_hash) }_Starting initial setup for server...")

        threads << Thread.new { execute_execution_hash_array(server_hash, execution_hash_array) }
      end

      threads.each { |thread| thread.join }

      @config['server_creation_queue'].each do |server_hash|
        @config[@options['env']]['server_passwords_bag_hash']["#{ server_hash['address'] }-root-pass"]   = server_hash['client_pass']
        @config[@options['env']]['server_passwords_bag_hash']["#{ server_hash['address'] }-deploy-pass"] = server_hash['deploy_password']
        @config[@options['env']]['server_passwords_bag_hash']["#{ server_hash['address'] }-name"]        = server_hash['node_name']
      end

      @config['ChefDataBag'].save_server_passwords_bag unless @config['in_server_creation_queue']
    end

    private

    def compile_root_execute_hash
      deploy_user = @config['cheftacular']['deploy_user']

      root_commands = [
        "cd /home",
        "adduser #{ deploy_user } --gecos \",,,,\" --disabled-password",
        "echo #{ deploy_user }:NEW_DEPLOY_PASS | chpasswd",
        "adduser #{ deploy_user } www-data",
        "adduser #{ deploy_user } sudo",
        "mkdir -p /home/#{ deploy_user }/.ssh",
        "touch /home/#{ deploy_user }/.ssh/authorized_keys && touch /home/#{ deploy_user }/.ssh/known_hosts",
        "chown -R #{ deploy_user }:www-data /home/#{ deploy_user }/.ssh",
        'sed -i "s/StrictModes yes/StrictModes yes\nPasswordAuthentication no\nUseDNS no\nAllowUsers deploy postgres\n/" /etc/ssh/sshd_config'.gsub('deploy', deploy_user),
        'sed -i "s/PermitRootLogin yes/PermitRootLogin no/" /etc/ssh/sshd_config'
      ]

      @config['default']['authentication_bag_hash']['authorized_keys'].each do |line|
        root_commands << "echo \"#{ line }\" >> /home/#{ deploy_user }/.ssh/authorized_keys"
      end

      { 
        run_as: 'ssh',
        command: root_commands.join(' && ').insert(-1, ' && service ssh restart'),
        retries: @config['cheftacular']['server_creation_tries'].to_i,
        use_root_pass: true
      }
    end

    def compile_deploy_execute_hash
      sudo = "echo NEW_DEPLOY_PASS | sudo -S"

      deploy_commands = [
        "#{ sudo } apt-get update",
        "#{ sudo } apt-get install curl #{ @config['cheftacular']['pre_install_packages'] } -y",
        "#{ sudo } DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -o Dpkg::Options::=\"--force-confdef\" -o Dpkg::Options::=\"--force-confold\""
      ]

      if @config['cheftacular']['install_rvm_on_boot']
        deploy_commands << "gpg --keyserver hkp://keys.gnupg.net --recv-keys #{ @config['cheftacular']['rvm_gpg_key'] }"
        deploy_commands << "curl -L https://get.rvm.io | bash -s stable"
      end

      { run_as: 'ssh', command_array: deploy_commands }
    end

    def compile_rvm_execute_hash
      rvm_source = "source /home/#{ @config['cheftacular']['deploy_user'] }/.rvm/bin/rvm &&"

      final_commands = [
        "#{ rvm_source } echo NEW_DEPLOY_PASS | rvmsudo -S rvm requirements",
        "#{ rvm_source } rvm install #{ @config['cheftacular']['ruby_version'] }",
        "#{ rvm_source } rvm alias create default #{ @config['cheftacular']['ruby_version'] }",
        "#{ rvm_source } rvm gemset empty --force"
      ]

      final_commands << "#{ rvm_source } rvm install 1.9.3-p327" if @config['cheftacular']['chef_version'].to_i < 12

      { run_as: 'ssh', command_array: final_commands }
    end

    def compile_install_rvm_sh_file_hashes ret_array=[]
      sudo = "echo NEW_DEPLOY_PASS | sudo -S"

      ssh_commands = [
        "#{ sudo } mv /home/#{ @config['cheftacular']['deploy_user'] }/rvm.sh /etc/profile.d",
        "#{ sudo } chmod 755 /etc/profile.d/rvm.sh",
        "#{ sudo } chown root:root /etc/profile.d/rvm.sh"
      ]

      ret_array << { run_as: 'scp', upload: "#{ @config['locs']['cheftacular-lib-files'] }/rvm.sh", to: "/home/#{ @config['cheftacular']['deploy_user'] }"}
      ret_array << { run_as: 'ssh', command: ssh_commands.join(' && ') }
      ret_array
    end

    def execute_execution_hash_array server_hash, execution_array, output=[], create_logs=true, log_sub_dir='initial-setup'
      execution_array.each do |execution_hash|
        ssh_arguments  = [server_hash['address']]
        ssh_arguments << ( execution_hash.has_key?(:use_root_pass) ? 'root' : @config['cheftacular']['deploy_user'] )
        ssh_arguments << [{ password: server_hash['client_pass'] }] if execution_hash.has_key?(:use_root_pass)
        begin
          case execution_hash[:run_as]
          when 'ssh'
            if execution_hash.has_key?(:command)
              Net::SSH.start(*ssh_arguments.flatten) do |ssh|
                output << ssh.exec!(replace_placeholders_in_command(server_hash, execution_hash[:command]))
              end
            end

            if execution_hash.has_key?(:command_array)
              execution_hash[:command_array].each do |command|
                puts("#{ server_name_output(server_hash) }_Preparing to execute #{ command }")

                Net::SSH.start(*ssh_arguments.flatten) do |ssh|
                  output << ssh.exec!(replace_placeholders_in_command(server_hash, command))
                end
              end
            end
          when 'scp'
            if execution_hash.has_key?(:upload) && execution_hash.has_key?(:to)
              puts("#{ server_name_output(server_hash) }_Preparing to upload #{ execution_hash[:upload] } to #{ execution_hash[:to] }")

              Net::SCP.upload!(server_hash['address'], @config['cheftacular']['deploy_user'], execution_hash[:upload], execution_hash[:to])
            end
          when 'raw'
            if execution_hash.has_key?(:command)
              output << `#{ replace_placeholders_in_command(server_hash, execution_hash[:command]) }`
            end

            if execution_hash.has_key?(:command_array)
              execution_hash[:command_array].each do |command|
                puts("#{ server_name_output(server_hash) }_Preparing to execute #{ command }")

                output << `#{ replace_placeholders_in_command(server_hash, command) }`
              end
            end
          end
        rescue Net::SSH::HostKeyMismatch => e
          puts "#{ server_name_output(server_hash) }_Has a host key mismatch! Rewriting known_hosts file..."

          @config['filesystem'].scrub_from_known_hosts(server_hash['address'])

          sleep 15

          retry
        rescue StandardError => e
          puts "#{ server_name_output(server_hash) }_@@@@@@@@@@@ Failing execution hash because of #{ e }!@@@@@@@@@@"
          puts "#{ e.backtrace.join("\n") }" if @options['verbose']

          if execution_hash.has_key?(:retries)
            execution_hash[:retries] = execution_hash[:retries] -= 1
            puts "#{ server_name_output(server_hash) }_@@@@@@@@@@@ There are #{ execution_hash[:retries] } tries left to evaluate the above command."

            sleep 60

            raise "#{ server_name_output(server_hash) }_@@@@@@@@@@@ Unable to complete setup process!@@@@@@@@@@" if execution_hash[:retries] <= 0
            retry
          end
        end
      end

      File.open("#{ @config['locs']['chef-log'] }/server-setup/#{ server_hash['node_name'] }-#{ log_sub_dir }-#{ @config['bootstrap_timestamp'] }.txt", 'a+') { |f| f.write(output.join("\n").scrub_pretty_text) }
    end

    def server_name_output server_hash
      "#{ server_hash['node_name'] }".ljust(17,'_') + "#{ server_hash['address'] }".ljust(18,'_')
    end

    def replace_placeholders_in_command server_hash, command
      command.gsub('NEW_DEPLOY_PASS', server_hash['deploy_password']).gsub('ADDRESS', server_hash['address']).gsub('CLIENT_PASS', server_hash['client_pass']).gsub('NODE_NAME', server_hash['node_name'])
    end
  end
end
