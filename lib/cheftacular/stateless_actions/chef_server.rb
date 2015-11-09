class Cheftacular
  class StatelessActionDocumentation
    def chef_server
      @config['documentation']['stateless_action'][__method__] ||= {}
      @config['documentation']['stateless_action'][__method__]['long_description'] = [
        "`cft chef_server [restart|processes|memory]` this command can be used to query the chef server for stats if the cheftacular.yml " +
        "has the chef_server key filled out. Useful for low resource chef-servers.",

        [
          "    1. `restart` restarts all chef processes on the chef server which may alleviate slow cheftacular load times for some users. (NOTE) " +
          "do not run this command while the chef-server is performing actions or instability may result! Not tested for high volume chef servers.",

          "    2. `processes` runs `ps aux` on the server to return the running processes and their stats.",

          "    3. `memory` runs `free -m` on the server to return the current memory usage.",

          "    4. NOTE! This command (and all arguments to it) bypass the normal environment loading like the help command.",

          "    5. NOTE 2! Cheftacular does not (and will not) support accessing your chef server over ssh with password auth. If you have done this, " +
          "you should feel bad and immediately switch ssh access to key authentication..."
        ]
      ]

      @config['documentation']['stateless_action'][__method__]['short_description'] = 'Allows you to check the state of the primary Chef server'

      @config['documentation']['application'][__method__] = @config['documentation']['stateless_action'][__method__]
    end
  end

  class InitializationAction
    def chef_server
      
    end
  end

  class StatelessAction
    def chef_server
      raise "This action can only be performed if the mode is set to devops" unless @config['helper'].running_in_mode?('devops')
      
      if @config['cheftacular']['chef_server'].nil? || !@config['cheftacular']['chef_server']['interactable']
        raise "Chef server is not currently set to be interactable with the chef-server command"
      end

      command = ARGV[1]

      raise "Unsupported command (#{ command }) for cft chef_server" unless command =~ /restart|processes|memory/

      command_prefix = case @config['cheftacular']['chef_server']['ssh_user']
                       when 'root' then ''
                       else             "echo #{ @config['cheftacular']['chef_server']['sudo_pass'] } | sudo -S "
                       end

      command = case command
                when 'restart'   then command_prefix + 'chef-server-ctl restart'
                when 'processes' then 'ps aux'
                when 'memory'    then 'free -m'
                end

      options = @options

      on ( @config['cheftacular']['chef_server']['ssh_user'] + "@" + @config['parser'].parse_base_chef_server_url ) do |host|

        puts "Beginning chef-server #{ command } run"

        start_chef_server_interactor(command, options)
      end
    end
  end
end

module SSHKit
  module Backend
    class Netssh
      def start_chef_server_interactor command, options, out=""
        puts capture( command )

        puts "Succeeded chef-server interaction run" unless options['quiet']
      end
    end
  end
end
