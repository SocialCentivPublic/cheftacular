class Cheftacular
  class StatelessActionDocumentation
    def initialize_data_bag_contents
      @config['documentation']['stateless_action'] <<  [
        "`cft initialize_data_bag_contents ENVIRONMENT_NAME` will ensure the data bags always have the correct structure before each run. " +
        "This command is run every time the gem is started and if called directly, will exit after completion."
      ]
    end
  end

  class StatelessAction
    def initialize_data_bag_contents env
      raise "Environment does not exist on chef server!" unless @config['chef_environments'].include?(env)

      @config['initializer'].initialize_audit_bag_contents env

      @config['initializer'].initialize_authentication_bag_contents

      @config['initializer'].initialize_chef_passwords_bag_contents env

      @config['initializer'].initialize_config_bag_contents env
        
      #@config['initializer'].initialize_server_passwords_bag_contents env

      @config['initializer'].initialize_addresses_bag_contents env

      #@config['initializer'].initialize_logs_bag_contents env

      #@config['ChefDataBag'].initialize_node_roles_bag_contents env
    end
  end

  class Initializer
    def initialize_authentication_bag_contents save_on_finish=false, exit_on_finish=false
      hash = @config['default']['authentication_bag_hash']

      auth_fix_message = "\n\n knife data bag edit default authentication --secret-file " +
      "#{ @config['locs']['chef'] }/#{ @config['cheftacular']['data_bag_key_file'] } \n\n"

      unless hash.has_key?('authorized_keys')
        hash['authorized_keys'] = []

        puts "Critical! No Authorized Keys for ssh detected in the default authentication bag! " +
        "These must be created. Use cft add_ssh_key_to_bag \"YOUR_SSH_KEY\"."

        save_on_finish, exit_on_finish = true,true
      end

      hash['specific_repository_authorized_keys'] = {} unless hash.has_key?('specific_repository_authorized_keys')

      @config['getter'].get_repo_names_for_repositories.each_key do |repo_name|
        unless hash['specific_repository_authorized_keys'].has_key?(repo_name)
          hash['specific_repository_authorized_keys'][repo_name] = []

          save_on_finish = true
        end 
      end

      hash['cloud_auth'] = {} unless hash.has_key?('cloud_auth')

      unless hash['cloud_auth'].has_key?(@options['preferred_cloud'])
        hash['cloud_auth'][@options['preferred_cloud']] = {}

        puts "Critical! No Cloud credentials detected for cloud #{ @options['preferred_cloud'] }, " +
        "Someone will need to edit the authentication data bag with the command " +
        auth_fix_message +
        "And add the correct cloud credentials to the hash for your preferred cloud!"

        save_on_finish, exit_on_finish = true,true
      end

      if hash['cloud_auth'].has_key?('rackspace')
        if !( hash['cloud_auth']['rackspace'].has_key?('username') || hash['cloud_auth']['rackspace'].has_key?('api_key') || hash['cloud_auth']['rackspace'].has_key?('email')) 

          hash['cloud_auth']['rackspace']['username'] = "" unless hash['cloud_auth']['rackspace'].has_key?('username')
          hash['cloud_auth']['rackspace']['api_key']  = "" unless hash['cloud_auth']['rackspace'].has_key?('api_key')
          hash['cloud_auth']['rackspace']['email']    = "" unless hash['cloud_auth']['rackspace'].has_key?('email')


          puts "Critical! No cloud credentials detected for the rackspace cloud_auth hash! There must be both a valid username and an api_key in this hash!"
          puts "Please run #{ auth_fix_message }Fill in the blank strings with your rackspace credentials."

          save_on_finish, exit_on_finish = true,true
        elsif hash['cloud_auth']['rackspace']['username'].empty? || hash['cloud_auth']['rackspace']['api_key'].empty? || hash['cloud_auth']['rackspace']['api_key'].empty?
          puts "Critical! Cloud credentials detected for the rackspace cloud_auth hash are blank!"
          puts "Please run #{ auth_fix_message }Fill in the blank strings with your rackspace credentials."

          exit_on_finish = true
        end
      end

      if @config['cheftacular']['git_based_deploys'] == 'true'
        if !hash.has_key?('git_private_key') || !hash.has_key?('git_public_key') || !hash.has_key?('git_OAuth')
          puts "Warning! github user credentials in default authentication bag were not found! Please run `cft help create_git_key` and then run that command itself!" unless @command == 'help'
        end
      end

      @config['ChefDataBag'].save_authentication_bag if save_on_finish

      exit if exit_on_finish
    end

    #User Action Generated: {"1.2.3.4-deploy-pass": "S325DSAGBCVfg5", "1.2.3.4-root-pass": "7dfDSFgb5%231", "1.2.3.4-name": "test"}
    def initialize_server_passwords_bag_contents env

    end

    #User Action Generated: {"name": "api1", "public": "1.2.3.4", "address": "10.208.1.2", "dn":"api1.example.com", "descriptor": "lb:my-backend-codebase"}
    def initialize_addresses_bag_contents env, save_on_finish=false
      hash = @config[env]['addresses_bag_hash']

      unless hash.has_key?('addresses')
        hash['addresses'] = []

        save_on_finish = true
      end

      @config['ChefDataBag'].save_addresses_bag(env) if save_on_finish
    end

    #User Action Generated: {"#{ NODE_NAME }-#{ COMMAND }": "CONTENT FROM RUN"}
    def initialize_log_bag_contents env

    end

    #TODO Reexamine, this might cause issues with the nested hash on encrypted saves
    def initialize_chef_passwords_bag_contents env, save_on_finish=false, exit_on_finish=false
      hash = @config[env]['chef_passwords_bag_hash']

      @config['cheftacular']['global_chef_passwords'].each_pair do |pass_key, pass_length|
        hash[pass_key] = @config['helper'].gen_pass(pass_length) unless hash.has_key?(pass_key)

        save_on_finish = true
      end

      @config['getter'].get_repo_names_for_repositories.each_pair do |repo_name, repo_hash|
        hash[repo_name] = {} unless hash.has_key?(repo_name)

        if repo_hash.has_key?('specific_chef_passwords')
          repo_hash['specific_chef_passwords'].each_pair do |pass_key, pass_length|
            unless hash[repo_name].has_key?(pass_key)
              hash[repo_name][pass_key] = @config['helper'].gen_pass(pass_length)

              save_on_finish = true
            end
          end
        end
        
        save_on_finish = true unless hash[repo_name].has_key?(repo_name)
      end

      @config['ChefDataBag'].save_chef_passwords_bag(env) if save_on_finish
    end

    def initialize_config_bag_contents main_env, save_on_finish=false, exit_on_finish=false
      hash = @config[main_env]['config_bag_hash']

      envs_to_build_in_hash = [main_env]

      config_fix_message = "\n\n knife data bag edit #{ main_env } config\n\n"

      if @config['cheftacular']['split_environments'].has_key?(main_env)
        @config['cheftacular']['split_environments'][main_env].each_key do |sub_env|
          envs_to_build_in_hash << sub_env
        end
      end

      envs_to_build_in_hash.each do |env|
        if !hash[env].has_key?('tld') || ( hash[env].has_key?('tld') && hash[env]['tld'].blank? )
          hash[env]['tld'] = "" unless hash[env].has_key?('tld')

          puts "WARNING! The config bag in environment: #{ main_env }(sub-env: #{ env }) does not have a top level domain set!"
          puts "Please run #{ config_fix_message }And update the tld key!"

          save_on_finish, exit_on_finish = true,true 
        end

        unless hash[env].has_key?('restore_backups')
          hash[env]['restore_backups'] = false

          save_on_finish = true
        end

        unless hash[env].has_key?('fetch_backups')
          hash[env]['fetch_backups'] = false

          save_on_finish = true
        end

        unless hash[env].has_key?('app_revisions')
          hash[env]['app_revisions'] = {}

          save_on_finish = true
        end
      end

      @config['ChefDataBag'].save_config_bag(main_env) if save_on_finish
    end

    # User Action Generated (see Cheftacular::StatelessAction.upload_nodes)
    def initialize_node_roles_bag_contents env
      hash = @config[env]['node_roles_bag_hash']

      unless hash.has_key?('node_roles')
        hash['node_roles'] = {}

        save_on_finish = true
      end

      @config['ChefDataBag'].save_node_roles_bag(env) if save_on_finish
    end

    # User Action Generated (see Cheftacular::StatelessAction.compile_audit_log)
    def initialize_audit_bag_contents env, save_on_finish=false
      hash = @config[env]['audit_bag_hash']

      unless hash.has_key?('audit_log')
        hash['audit_log'] = {}

        save_on_finish = true
      end

      @config['ChefDataBag'].save_audit_bag(env) if save_on_finish
    end
  end
end
