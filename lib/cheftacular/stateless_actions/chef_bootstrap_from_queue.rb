
class Cheftacular
  class StatelessActionDocumentation
    def chef_bootstrap_from_queue
      @config['documentation']['stateless_action'][__method__] ||= {}
      @config['documentation']['stateless_action'][__method__]['long_description'] = [
        "`cft chef_bootstrap_from_queue` allows you to register a node in the chef system, " + 
        "remove any lingering data that may be associated with it and update the node's runlist if it has an entry in nodes_dir for its NODE_NAME.",

        [
          "    1. This command is part of the `cft full_bootstrap` command and cannot be called directly"
        ]
      ]

      @config['documentation']['stateless_action'][__method__]['short_description'] = 'Bootstraps basic chef properties on the target server'
    end
  end

  class StatelessAction
    def chef_bootstrap_from_queue threads=[]
      raise "This action is not meant to be called directly!" if !@options['in_scaling'] && !@options['in_single_server_creation']

      #@config['stateless_action'].remove_client #just in case

      execution_hash_array = compile_chef_bootstrap_commands

      @config['bootstrap_timestamp'] ||= Time.now.strftime("%Y%m%d%H%M%S")

      @config['server_creation_queue'].each do |server_hash|
        puts("#{ server_name_output(server_hash) } Starting chef-client installation...") unless @options['quiet']

        threads << Thread.new { execute_execution_hash_array(server_hash, execution_hash_array) }
      end

      threads.each { |thread| thread.join }

      @options['force_yes'] = true # have the upload_nodes grab the new nodes

      @config['stateless_action'].upload_nodes(true)
    end

    private

    def compile_chef_bootstrap_commands final_command=[]
      sudo = "echo NEW_DEPLOY_PASS | sudo -S"

      if @config['cheftacular']['chef_version'].to_i >= 12
        commands = [
          "curl -L https://www.opscode.com/chef/install.sh > ~/chef-install.sh",
          "#{ sudo } bash /home/#{ @config['cheftacular']['deploy_user'] }/chef-install.sh",
          "rm ~/chef-install.sh"
        ]

        final_command << { run_as: 'ssh', command_array: commands }
      end

      final_command << knife_bootstrap_command
      final_command << export_data_bag_key_file_command
      final_command << move_data_bag_key_file_command

      final_command
    end

    def knife_bootstrap_command
      user     = @config['cheftacular']['deploy_user']
      chef_ver = @config['cheftacular']['chef_version'].to_i >= 12 ? '12.4.0' : '11.16.4'

      { run_as: 'raw', command: "knife bootstrap ADDRESS -x #{ user } -P NEW_DEPLOY_PASS -N NODE_NAME --sudo --use-sudo-password --bootstrap-version #{ chef_ver }" }
    end

    def export_data_bag_key_file_command
      chef_loc, key_file, user, address = set_data_bag_key_variables

      #"scp -oStrictHostKeyChecking=no #{ chef_loc }/#{ key_file } #{ user }@#{ address }:/home/#{ user }"
      { run_as: 'scp', upload: "#{ chef_loc }/#{ key_file }", to: "/home/#{ user }" }
    end

    def move_data_bag_key_file_command
      chef_loc, key_file, user, address = set_data_bag_key_variables

      #"ssh -t -oStrictHostKeyChecking=no #{ user }@#{ address } \"#{ @config['helper'].sudo(address) } mv -f /home/#{ user }/#{ key_file } /etc/chef\""
      { run_as: 'ssh', command: "echo NEW_DEPLOY_PASS | sudo -S mv -f /home/#{ user }/#{ key_file } /etc/chef" }
    end

    def set_data_bag_key_variables
      [ @config['locs']['chef'], @config['cheftacular']['data_bag_key_file'], @config['cheftacular']['deploy_user'], 'ADDRESS' ]
    end
  end
end
