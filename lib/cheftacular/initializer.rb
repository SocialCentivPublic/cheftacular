
class Cheftacular
  class Initializer
    def initialize options, config
      @options, @config  = options, config

      initialize_yaml_configuration

      initialize_default_cheftacular_options

      initialize_locations

      initialize_monkeypatches unless @config['helper'].running_on_chef_node?

      initialize_arguments

      initialize_sub_environment

      initialize_cloud_options

      initialize_documentation_hash

      initialize_ruby_config

      initialize_ridley unless @config['helper'].is_initialization_command?(ARGV[0])

      initialize_classes

      initialize_directories

      initialize_cloud_checks

      unless @config['helper'].is_initialization_command?(ARGV[0])

        @config['helper'].completion_rate? 0, 'initializer'

        @config['helper'].completion_rate? 10, 'initializer'

        initialize_ridley_environments

        @config['helper'].completion_rate? 20, 'initializer'

        initialize_ridley_roles_and_nodes

        @config['helper'].completion_rate? 30, 'initializer'

        initialize_data_bags_for_environment @options['env'], true

        @config['helper'].completion_rate? 90, 'initializer'

        initialize_passwords @options['env']

        @config['helper'].completion_rate? 100, 'initializer'

        initialize_version_check if @config['cheftacular']['strict_version_checks']

        initialize_auditing_checks if @config['cheftacular']['auditing']

        initialize_chef_repo_up_to_date if @config['cheftacular']['keep_chef_repo_cheftacular_yml_up_to_date']
      end
    end

    #changes to arguments should show up in the documentation methods in their appropriate method file
    def initialize_arguments
      OptionParser.new do |opts|
        opts.banner = "Usage: cft command [repository] [opts]"

        # Environment arguments

        opts.on('-b', '--datastaging', 'Set the environment to datastaging') do
          @options['env'] = 'datastaging'
        end

        opts.on('-d', '--dev-remote', "Set the environment to devremote") do
          @options['env'] = 'devremote'
        end

        opts.on('--env ENV', 'Set the environment to one you specify') do |env|
          @options['env'] = env
        end

        opts.on('-p', '--prod', "Set the environment to production") do
          @options['env'] = 'production'
        end

        opts.on('-Q','--qa', 'Set the environment to QA') do
          @options['env'] = 'qa'
        end

        opts.on('-s', '--staging', "Set the environment to staging (this is the default)") do
          @options['env'] = 'staging'
        end

        opts.on('--split-env SPLIT_ENV_NAME', "Set the sub-environment to the specified split_env") do |sub_env|
          @options['sub_env'] = sub_env
        end

        opts.on('-t', '--test', 'Set the environment to test') do
          @options['env'] = 'test'
        end

        # General arguments

        opts.on('-a', '--address ADDRESS', "Run your command against this address") do |addr|
          @options['address'] = addr
        end

        opts.on('-D', '--debug', "Activate extremely verbose logging") do
          @options['debug'] = true
          @options['verbose'] = true
        end

        opts.on('-n', '--node-name NAME', "Run your command against this node_name") do |name|
          @options['node_name'] = name
        end

        opts.on('-q', '--quiet', "Deactivates most forms of output") do
          @options['quiet'] = true
        end

        opts.on('-r', '--role-name NAME', "Run your command against this role_name") do |name|
          @options['role'] = name
        end

        opts.on('-R', '--repository NAME', 'Run your command against this repository / context') do |name|
          @options['repository'] = name
        end

        opts.on('-v', '--verbose', "Activates slightly more verbose logging, also causes commands to output to terminal and logs") do
          @options['verbose'] = true
        end

        opts.on('--no-logs', "Do not make logs for any command") do
          @options['no_logs'] = true
        end

        opts.on('-h', '--help', 'Displays the README') do
          @config['helper'].display_readme

          puts "Remember, you can also utilize the cft help command!"

          exit
        end

        # Action Arguments

        opts.on('-e', '--except-role NAME', 'For deployments, will prevent the deploy from triggering on servers with this role') do |name|
          @options['negative_role'] = name
        end

        opts.on('-z', '--unset-revision', 'Tells the chef-server that we want to return to using the default revision for a repository') do
          @options['unset_revision'] = true
        end

        opts.on('-Z REVISION', '--revision REVISION', "Tells the chef-server what branch / revision it should deploy for a repository") do |revision|
          @options['target_revision'] = revision
        end

        # client-list
        opts.on('-W', '--with-priv', "On client-list this will show each server's private addresses") do
          @options['with_private'] = true
        end 

        # cft log options
        opts.on('--nginx', "On cft log pass this argument to fetch nginx logs as well as application logs") do
          @options['get_nginx_logs'] = true
        end

        opts.on('--full', "On cft log pass this argument to fetch the FULL log") do
          @options['get_full_logs'] = true
        end

        opts.on('-l INTEGER', '--lines INTEGER', "On cft log pass this argument to fetch the last X lines of logs") do |num|
          @options['get_log_lines'] = num
        end

        opts.on('--num INTEGER', "On cft log pass this argument to fetch the last X lines of logs") do |num|
          @options['get_log_lines'] = num
        end

        # cft tail options
        opts.on('--tail-grep PATTERN', "On cft tail pass this argument to only pull a specific pattern from logs of a file") do |pattern|
          @options['tail_grep'] = pattern
        end

        #cft run
        opts.on('--all', "On cft run COMMAND you can pass --all to run the command on multiple nodes") do 
          @options['run_on_all'] = true
        end

        #cloud_bootstrap

        opts.on('--with-dn DOMAIN_NAME', "On hip rax_bootstrap allows you to specify a domain structure other than the default environment one") do |domain|
          @options['with_dn'] = domain
        end

        #cloud

        opts.on('-o', '--cloud CLOUD_NAME', "On cft cloud calls, set the cloud to the one you specify") do |cloud_name|
          @options['preferred_cloud'] = cloud_name
        end

        opts.on('--rax', "On cft cloud calls, set the cloud to Rackspace") do
          @options['preferred_cloud'] = 'rackspace'
        end

        opts.on('--aws', "On cft cloud calls, set the cloud to Amazon Web Services") do
          @options['preferred_cloud'] = 'aws'
        end

        opts.on('--do', "On cft cloud calls, set the cloud to DigitalOcean") do
          @options['preferred_cloud'] = 'digitalocean'
        end

        opts.on('--region REGION', 'On cft cloud calls, set the cloud region to perform operations on to this region') do |region|
          @options['preferred_cloud_region'] = region
        end

        opts.on('--image IMAGE', 'On cft cloud calls, set the default image to this image (can be shorthand like "Ubuntu 14.04"') do |image|
          @options['preferred_cloud_image'] = image
        end

        opts.on('--virtualization-mode MODE', 'On cft cloud calls, set the default virtualization mode to this (On rackspace, only PV or PVHVM are supported)') do |v_mode|
          @options['virtualization_mode'] = v_mode
        end

        opts.on('--route-dns-changes-via SERVICE', 'On cft cloud calls, set the default dns provider to this service') do |service|
          @options['route_dns_changes_via'] = service
        end

        #file | chef_server
        opts.on('--save-to-file FILE_NAME', 'On cft file or chef_server, this option can be used to save the output of the file display methods to your system. Also works in the fetch context') do |path|
          @options['save_to_file'] = path
        end

      end.parse!
    end

    def initialize_yaml_configuration
      @config['cheftacular'] = @config['helper'].get_cheftacular_yml_as_hash
    end

    def initialize_default_cheftacular_options
      @options['env']        = @config['cheftacular']['default_environment'] if @config['cheftacular'].has_key?('default_environment')
      @options['repository'] = @config['cheftacular']['default_repository'] if @config['cheftacular'].has_key?('default_repository')
    end

    def initialize_monkeypatches
      if File.exists?(File.expand_path("#{ @config['locs']['app-root'] }/config/initializers/cheftacular.rb"))
        puts "Cheftacular Monkeypatch file detected! Preparing to require..."

        require "#{ @config['locs']['app-root'] }/config/initializers/cheftacular"
      end
    end

    def initialize_cloud_options
      @config['helper'].set_cloud_options
    end

    #only matters to the config_bag and it's hash. Used to fetch keys within the bag for certain commands
    def initialize_sub_environment
      @options['sub_env'] ||= @options['env']
    end

    def initialize_documentation_hash
      @config['documentation'] ||= {}
      @config['documentation']['arguments']        ||= []
      @config['documentation']['action']           ||= []
      @config['documentation']['stateless_action'] ||= []
      @config['documentation']['application']      ||= []
      @config['documentation']['devops']           ||= []
    end

    def initialize_locations
      locs ||= {}

      if @config['helper'].running_in_mode? 'application'
        locs['root']     = Dir.getwd
        locs['chef-log'] = File.join( locs['root'], 'log')
        locs['app-root'] = locs['root']
      elsif @config['helper'].running_on_chef_node?
        locs['chef-log'] = File.expand_path("/root/sensu_log")
        locs['chef']     = File.expand_path("/etc/chef")
        locs['ssh']      = File.expand_path('/home/deploy/.ssh')
      end

      locs['chef-repo']             = Dir.getwd
      locs['roles']                 = File.expand_path("#{ locs['chef-repo'] }/roles")
      locs['nodes']                 = File.expand_path("#{ locs['chef-repo'] }/nodes_dir") #DO NOT RENAME THIS TO NODES
      locs['root']                  = locs['chef-repo']                                    unless locs['root']
      locs['app-root']              = locs['chef-repo']                                    unless locs['app-root']
      locs['chef']                  = File.expand_path("~/.chef")                          unless locs['chef']
      locs['cookbooks']             = File.expand_path("#{ locs['chef-repo'] }/cookbooks")
      locs['berks']                 = File.expand_path('~/.berkshelf/cookbooks')
      locs['wrapper-cookbooks']     = @config['cheftacular']['wrapper_cookbooks']
      locs['ssh']                   = File.expand_path('~/.ssh')
      locs['chef-log']              = File.expand_path("#{ locs['root']}/log")             unless locs['chef-log']
      locs['app-tmp']               = File.expand_path("#{ locs['app-root']}/tmp")
      locs['examples']              = File.expand_path("../../../examples", __FILE__)
      locs['cheftacular-lib']       = File.expand_path("../..", __FILE__)
      locs['cheftacular-lib-files'] = locs['cheftacular-lib'] + '/cheftacular/files'

      @config['locs'] = locs
    end

    def initialize_ridley
      return unless @config['ridley'].nil?

      @config['data_bag_secret'] = File.read(File.expand_path("#{ @config['locs']['chef'] }/#{ @config['cheftacular']['data_bag_key_file'] }")).chomp

      Ridley::Logging.logger.level = Logger.const_get 'ERROR'

      @config['ridley'] = Ridley.new(
        server_url:                @config['cheftacular']['chef_server_url'],
        client_name:               (@config['helper'].running_on_chef_node? ? @config['helper'].parse_node_name_from_client_file : @config['cheftacular']['cheftacular_chef_user']),
        client_key:                File.expand_path("#{ @config['locs']['chef'] }/#{ @config['helper'].running_on_chef_node? ? 'client' : @config['cheftacular']['cheftacular_chef_user'] }.pem"),
        encrypted_data_bag_secret: @config['data_bag_secret'],
        ssl:                       { verify: @config['cheftacular']['ssl_verify'] }
      )
    end

    def initialize_ridley_environments
      @config['chef_environments'] ||= @config['ridley'].environment.all.map { |env| env.name }.delete_if { |env| env == '_default' }
    end

    def initialize_ridley_roles_and_nodes
      @config['chef_nodes'] ||= @config['ridley'].node.all
      @config['chef_roles'] ||= @config['ridley'].role.all
    end

    def initialize_data_bags_for_environment env, in_initializer=false, bags_to_load=[]
      @config['ChefDataBag'] ||= Cheftacular::ChefDataBag.new(@options, @config)

      puts("Loading additional data bag data from chef server for environment \"#{ env }\" for bags: #{ bags_to_load.join(', ') }") if !in_initializer && !@options['quiet']

      @config['ChefDataBag'].init_bag('default', 'authentication') if bags_to_load.empty? || bags_to_load.include?('authentication')

      @config['ChefDataBag'].init_bag('default', 'cheftacular', false) if bags_to_load.empty? || bags_to_load.include?('cheftacular')

      @config['ChefDataBag'].init_bag('default', 'environment_config', false) if bags_to_load.empty? || bags_to_load.include?('environment_config')

      @config['helper'].completion_rate?(38, 'initializer') if in_initializer

      @config['ChefDataBag'].init_bag(env, 'addresses', false) if bags_to_load.empty? || bags_to_load.include?('addresses')

      @config['helper'].completion_rate?(46, 'initializer') if in_initializer

      @config['ChefDataBag'].init_bag(env, 'audit', false) if bags_to_load.empty? || bags_to_load.include?('audit')

      @config['helper'].completion_rate?(54, 'initializer') if in_initializer

      @config['ChefDataBag'].init_bag(env, 'chef_passwords') if bags_to_load.empty? || bags_to_load.include?('chef_passwords')

      @config['helper'].completion_rate?(62, 'initializer') if in_initializer

      @config['ChefDataBag'].init_bag(env, 'config', false) if bags_to_load.empty? || bags_to_load.include?('config')

      @config['helper'].completion_rate?(70, 'initializer') if in_initializer

      @config['ChefDataBag'].init_bag(env, 'logs', false) if bags_to_load.empty? || bags_to_load.include?('logs')

      @config['helper'].completion_rate?(78, 'initializer') if in_initializer

      @config['ChefDataBag'].init_bag(env, 'node_roles', false) if bags_to_load.empty? || bags_to_load.include?('node_roles')

      @config['helper'].completion_rate?(86, 'initializer') if in_initializer

      @config['ChefDataBag'].init_bag(env, 'server_passwords') if bags_to_load.empty? || bags_to_load.include?('server_passwords')
    end

    def initialize_ruby_config
      @config['ruby_string'] = @config['cheftacular']['ruby_version']

      begin
        @config['ruby_string'] = File.read(File.expand_path("#{ locs['app-root'] }/.ruby-version")) unless @config['ruby_string']
      rescue StandardError => e
        msg = [
          "Please run this in the root of your application directory,",
          "a ruby string to run commands against was not found in either your cheftacular.yml file or your .ruby-version file."
        ].join(' ')

        @config['error'].exception_output msg, e
      end
      
      @config['ruby_string'] = "ruby-" + @config['ruby_string'] unless @config['ruby_string'].include?('ruby-')

      #TODO Reevaluate for non-rvm setups
      @config['bundle_command'] = "/home/#{ @config['cheftacular']['deploy_user'] }/.rvm/gems/#{ @config['ruby_string'].chomp }@global/bin/bundle"
    end

    def initialize_passwords env, refresh_bag=false
      @config['server_passwords'] ||= {}

      @config[env]['server_passwords_bag'].reload if refresh_bag

      @config[env]['server_passwords_bag_hash'] = @config[env]['server_passwords_bag'].decrypt.to_hash if refresh_bag

      #data_hash will be { server_name: 'SERVER_NAME', password: 'PASSWORD_STRING' }
      @config[env]['server_passwords_bag_hash'].each_pair do |key, data_hash|
        if key.include?('-deploy-pass')
          addr = key.split('-deploy-pass').first

          @config['server_passwords'][addr] = data_hash
        end
      end
    end

    def initialize_version_check detected_version=""
      current_version = Cheftacular::VERSION

      detected_version = File.exists?( @config['filesystem'].current_version_file_path ) ? File.read( @config['filesystem'].current_version_file_path ) : @config['helper'].fetch_remote_version

      if @config['helper'].is_higher_version? detected_version, current_version
        puts "\n Your Cheftacular is out of date. Currently #{ current_version } and remote version is #{ detected_version }.\n"

        puts "Please update the gemfile to #{ detected_version }, bundle install and then restart this process.\n"

        exit
      else
        unless File.exists?( @config['filesystem'].current_version_file_path )
          puts "Creating file cache for #{ Time.now.strftime("%Y%m%d") } (#{ detected_version }). No new version detected."

          @config['filesystem'].write_version_file detected_version
        end
      end
    end

    def initialize_auditing_checks
      unless File.exists? @config['filesystem'].current_audit_file_path
        puts "Creating file cache for #{ Time.now.strftime("%Y%m%d") } audit data..."

        @config['auditor'].write_audit_cache_file
      end
    end

    def initialize_classes
      @config['auditor']                        = Cheftacular::Auditor.new(@options, @config)
      @config['parser']                         = Cheftacular::Parser.new(@options, @config)
      @config['getter']                         = Cheftacular::Getter.new(@options, @config)
      @config['action']                         = Cheftacular::Action.new(@options, @config)
      @config['stateless_action']               = Cheftacular::StatelessAction.new(@options, @config)
      @config['encryptor']                      = Cheftacular::Encryptor.new(@config['data_bag_secret'])
      @config['decryptor']                      = Cheftacular::Decryptor.new(@config['data_bag_secret'])
      @config['action_documentation']           = Cheftacular::ActionDocumentation.new(@options, @config)
      @config['stateless_action_documentation'] = Cheftacular::StatelessActionDocumentation.new(@options, @config)
      @config['error']                          = Cheftacular::Error.new(@options, @config)
      @config['dummy_sshkit']                   = SSHKit::Backend::Netssh.new(SSHKit::Host.new('127.0.0.1'))
      @config['DNS']                            = Cheftacular::DNS.new(@options, @config)
      @config['cloud_provider']                 = Cheftacular::CloudProvider.new(@options, @config)
    end

    def initialize_directories
      ['applog', 'deploy', 'failed-deploy', 'rolelog', 'rvm', 'stashedlog'].each do |sub_log_directory|
        FileUtils.mkdir_p File.join( @config['locs']['chef-log'], sub_log_directory )
      end

      FileUtils.mkdir_p File.join( @config['locs']['app-tmp'], @config['helper'].declassify)

      FileUtils.mkdir_p @config['filesystem'].current_nodes_file_cache_path

      @config['filesystem'].cleanup_file_caches
    end

    def initialize_cloud_checks exit_on_finish = false
      hash = @config['cheftacular']['cloud_authentication']

      unless hash.has_key?(@options['preferred_cloud'])
        puts "Critical! No Cloud credentials detected for your preferred cloud #{ @options['preferred_cloud'] }, " +
        "Please update the cheftacular.yml cloud_authentication:#{ @options['preferred_cloud'] } key!"

        exit_on_finish = true
      end

      if hash.has_key?('rackspace')
        if !( hash['rackspace'].has_key?('username') || hash['rackspace'].has_key?('api_key') || hash['rackspace'].has_key?('email')) 

          puts "Critical! No cloud credentials detected for the rackspace cloud_authentication hash! There must be both a valid username and an api_key in this hash!"
          puts "Please update the cheftacular.yml cloud_authentication:rackspace key!"

          exit_on_finish = true
        elsif hash['rackspace']['username'].empty? || hash['rackspace']['api_key'].empty? || hash['rackspace']['email'].empty?
          puts "Critical! Cloud credentials detected for the rackspace cloud_authentication hash are blank!"
          puts "Please update the cheftacular.yml cloud_authentication:rackspace key!"

          exit_on_finish = true
        end
      end

      if hash.has_key?('digitalocean')
        if !( hash['digitalocean'].has_key?('client_id') || hash['digitalocean'].has_key?('api_key')) 

          puts "Critical! No cloud credentials detected for the digitalocean cloud_authentication hash! There must be both a valid client_id and an api_key in this hash!"
          puts "Please update the cheftacular.yml cloud_authentication:digitalocean key!"

          exit_on_finish = true
        elsif hash['digitalocean']['client_id'].empty? || hash['digitalocean']['api_key'].empty?
          puts "Critical! Cloud credentials detected for the digitalocean cloud_authentication hash are blank!"
          puts "Please update the cheftacular.yml cloud_authentication:digitalocean key!"

          exit_on_finish = true
        end
      end

      exit if exit_on_finish
    end

    def initialize_chef_repo_up_to_date
      if @config['helper'].running_in_mode?('devops')
        @config['cheftacular']['wrapper_cookbooks'].split(',').each do |wrapper_cookbook|
          parsed_hash = if File.exists?( @config['filesystem'].current_chef_repo_cheftacular_file_cache_path ) 
                          File.read( @config['filesystem'].current_chef_repo_cheftacular_file_cache_path )
                        else
                          Digest::SHA2.hexdigest(@config['helper'].compile_chef_repo_cheftacular_yml_as_hash.to_yaml.to_s)
                        end

          wrapper_cookbook_cheftacular_loc = "#{ @config['locs']['cookbooks'] }/#{ wrapper_cookbook }" +
            @config['cheftacular']['location_of_chef_repo_cheftacular_yml'] + '/cheftacular.yml'

          unless File.exist?(wrapper_cookbook_cheftacular_loc)
            puts "Wrapper cookbook \"#{ wrapper_cookbook }\" does not have a cheftacular.yml file in #{ @config['cheftacular']['location_of_chef_repo_cheftacular_yml'] }! Creating..."

            @config['filesystem'].write_chef_repo_cheftacular_yml_file wrapper_cookbook_cheftacular_loc
          end

          if parsed_hash == Digest::SHA2.hexdigest(File.read(wrapper_cookbook_cheftacular_loc))
            next if File.exists?( @config['filesystem'].current_chef_repo_cheftacular_file_cache_path )
          else
            puts "Wrapper cookbook (#{ wrapper_cookbook }) does not have a current cheftacular.yml file in #{ @config['cheftacular']['location_of_chef_repo_cheftacular_yml'] }\"! Overwriting..."

            @config['filesystem'].write_chef_repo_cheftacular_yml_file wrapper_cookbook_cheftacular_loc

            initialize_cheftacular_data_bag_contents if @config['cheftacular']['also_keep_cheftacular_data_bag_up_to_date']
          end

          puts "Creating file cache for #{ Time.now.strftime("%Y%m%d") }'s cheftacular.yml."

          @config['filesystem'].write_chef_repo_cheftacular_cache_file parsed_hash
        end
      end
    end

    def initialize_bag_for_all_environments bag_name, total_percent=100
      total_bags   = @config['chef_environments'].count
      current_bags = 1

      @config['chef_environments'].each do |env|
        @config['ChefDataBag'].init_bag env, bag_name

        @config['helper'].completion_rate? (percent + (( (current_bags).to_f / total_bags.to_f ) * 100) / ( 100.to_f / total_percent.to_f ) ), __method__

        current_bags += 1
      end
    end
  end
end
