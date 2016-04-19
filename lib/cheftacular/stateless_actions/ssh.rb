
class Cheftacular
  class StatelessActionDocumentation
    def ssh
      @config['documentation']['stateless_action'][__method__] ||= {}
      @config['documentation']['stateless_action'][__method__]['long_description'] = [
        "`cft ssh NODE_NAME [exec] [command]` ssh you into the node name you are trying to access. "+
        "It will also drop the server's sudo password into your clipboard. ",

        [
          "    1. `cft ssh NODE_NAME exec COMMAND` will execute a command on the server as root"
        ]
      ]

      @config['documentation']['stateless_action'][__method__]['short_description'] = 'SSHs you into a node regardless of environment'

      @config['documentation']['application'][__method__] = @config['documentation']['stateless_action'][__method__]
    end
  end

  class StatelessAction
    def ssh node_name='', command=''
      @options['node_name'] = ARGV[1] unless @options['node_name']

      command = ARGV[3] if command.blank? && ARGV[2] == 'exec' 

      @config['stateless_action'].pass(@options['node_name']) if command.blank?

      nodes = @config['error'].is_valid_node_name_option?

      if !command.blank? && nodes.first.chef_environment != @options['env']
        @config['initializer'].initialize_data_bags_for_environment nodes.first.chef_environment, false, ['addresses', 'server_passwords']

        @config['initializer'].initialize_passwords nodes.first.chef_environment
      end

      nodes.each do |n|
        puts("Beginning ssh run for #{ n.name } (#{ n.public_ipaddress })") unless @options['quiet']

        start_ssh_session(n.public_ipaddress, command)
      end

      @config['auditor'].notify_slack_on_completion("ssh run completed on #{ @options['node_name'] } (#{ nodes.first.public_ipaddress })\n") if @config['cheftacular']['auditing'] && command.blank?
    end

    private

    def start_ssh_session ip_address, command, out=""
      unless command.blank?
        out << (`ssh #{ Cheftacular::SSH_INLINE_VARS } -tt #{ @config['cheftacular']['deploy_user'] }@#{ ip_address } "#{ @config['helper'].sudo(ip_address) } #{ command }" > /dev/tty`)

        puts out
      end

      `ssh #{ Cheftacular::SSH_INLINE_VARS } -t #{ @config['cheftacular']['deploy_user'] }@#{ ip_address } > /dev/tty` if command.blank?
    end
  end
end
