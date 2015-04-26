#interact with an rvm installation on servers
class Cheftacular
  class StatelessActionDocumentation
    def rvm
      @config['documentation']['stateless_action'] <<  [
        "`cft rvm [COMMAND] [ADDITIONAL_COMMANDS]*` will run rvm commands on the remote servers. " +
        "Output from this command for each server will go into your rvm directory under the log directory. " +
        "Please refer to [the rvm help page](https://rvm.io/rvm) for more information on rvm commands.",

        [
          "    1. When no commands are passed, rvm will just run `rvm list` on each server on all servers in " +
          "the current environment.",

          "    2. When `list|list_rubies` is passed, rvm will run `rvm list rubies` on all servers in the " +
          "current environment.",

          "    3. When `install RUBY_TO_INSTALL` is passed, rvm will attempt to install that ruby on each " +
          "system in the current environment. It is a good idea to use strings like ruby-2.2.1",

          "    4. `run [RVM_COMMANDS]+` will run the rest of the arguments as a complete rvm command. An example " +
          "of this being `cft rvm run gemset update`. This will run on all servers in the current environment.",

          "    5. `all_environments [RVM_COMMANDS]+` will run the rest of the arguments as a complete rvm command " +
          "*on all of the servers in every environment*.",

          "    6. `test [RVM_COMMANDS]+` will run the rest of the arguments as a complete rvm command with scoping. " +
          "By default, rvm commands run against all servers in the environment but with test you can pass -n NODE_NAME " +
          " or -r ROLE_NAME flags to scope the servers the rvm command will be run on. Useful for testing.",

          "    7. `upgrade_rvm` will run `rvm get stable --auth-dotfiles` on all servers for the current environment. " +
          "It will also check and attempt to upgrade pre 1.25 installations of RVM to 1.26+ (which requires a GPG key)."
        ]
      ]
    end
  end

  class StatelessAction
    def rvm command=''
      raise "This action can only be performed if the mode is set to devops" unless @config['helper'].running_in_mode?('devops')

      command = case ARGV[1]
                when nil                then 'list'
                when /list|list_rubies/ then 'list rubies'
                when 'install'          then "install #{ ARGV[2] }"
                when 'run'              then ARGV[2..(ARGV.length-1)].join(' ')
                when 'all_environments' then ARGV[2..(ARGV.length-1)].join(' ')
                when 'test'             then ARGV[2..(ARGV.length-1)].join(' ')
                when 'upgrade_rvm'      then 'get stable --auto-dotfiles'
                else                         'list'
                end

      if @config['cheftacular']['rvm_gpg_key'].nil? || @config['cheftacular']['rvm_gpg_key'].blank?
        raise "GPG Key not found in cheftacular.yml! Please update your rvm_gpg_key in the file!"
      end

      nodes = ARGV[1] == 'test' ? @config['getter'].get_true_node_objects : @config['getter'].get_true_node_objects(true)

      nodes = @config['parser'].exclude_nodes( nodes, [{ unless: { env: @options['env'] }}] ) unless ARGV[1] == 'all_servers'

      @config['chef_environments'].each do |env|
        @config['initializer'].initialize_data_bags_for_environment env, false, ['addresses', 'server_passwords']

        @config['initializer'].initialize_passwords env
      end if ARGV[1] == 'all_servers'

      options, locs, ridley, logs_bag_hash, pass_bag_hash, bundle_command, cheftacular, passwords = @config['helper'].set_local_instance_vars

      on ( nodes.map { |n| "deploy@" + n.public_ipaddress } ), in: :groups, limit: 5, wait: 2 do |host|
        n = get_node_from_address(nodes, host.hostname)

        puts "Beginning run of \"rvm #{ command }\" for #{ n.name } (#{ n.public_ipaddress })"

        start_rvm( n.name, n.public_ipaddress, options, locs, passwords, command, cheftacular )
      end
    end
  end
end

module SSHKit
  module Backend
    class Netssh
      def start_rvm name, ip_address, options, locs, passwords, command, cheftacular, out=""
        log_loc, timestamp = set_log_loc_and_timestamp(locs)
        upgrade_rvm        = command.include?('get stable')
        rvm_location       = "/home/#{ cheftacular['deploy_user'] }/.rvm/bin/rvm"

        puts "Generating rvm log file for #{ name } (#{ ip_address }) at #{ log_loc }/rvm/#{ name }-rvm-#{ timestamp }.txt"


        if !test("[ -e /home/#{ cheftacular['deploy_user'] }/.rvm/bin/rvm ]") #true if file exists
          puts "#{ name } (#{ ip_address }) does not have a rvm bin command at the moment! Updating installation to latest..."

          upgrade_rvm = true
        end

        if upgrade_rvm
          out << sudo_capture( passwords[ip_address], :chown, "#{ cheftacular['deploy_user'] }:root", '-R', "/home/#{ cheftacular['deploy_user'] }/.gnupg")

          out << capture( :gpg, '--keyserver hkp://keys.gnupg.net', "--recv-keys #{ cheftacular['rvm_gpg_key'] }")

          rvm_location = "/home/#{ cheftacular['deploy_user'] }/.rvm/.rvm/bin/rvm" if test("[ -e /home/#{ cheftacular['deploy_user'] }/.rvm/.rvm/bin/rvm ]")
        end

        out << capture( rvm_location, command )

        ::File.open("#{ log_loc }/rvm/#{ name }-rvm-#{ timestamp }.txt", "w") { |f| f.write(out.scrub_pretty_text) } unless options['no_logs']

        puts(out.scrub_pretty_text) if options['output'] || options['verbose']

        puts "Succeeded run of \"rvm #{ command }\" for #{ name } (#{ ip_address })"
      end
    end
  end
end
