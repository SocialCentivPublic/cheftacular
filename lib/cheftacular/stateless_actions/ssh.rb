
class Cheftacular
  class StatelessActionDocumentation
    def ssh
      @config['documentation']['stateless_action'][__method__] ||= {}
      @config['documentation']['stateless_action'][__method__]['long_description'] = [
        "`cft ssh NODE_NAME` ssh you into the node name you are trying to access. "+
        "It will also drop the server's sudo password into your clipboard. "
      ]

      @config['documentation']['stateless_action'][__method__]['short_description'] = 'SSHs you into a node regardless of environment'

      @config['documentation']['application'][__method__] = @config['documentation']['stateless_action'][__method__]
    end
  end

  class StatelessAction
    def ssh
      @options['node_name'] = ARGV[1] unless @options['node_name']

      @config['stateless_action'].pass(@options['node_name'])

      nodes = @config['error'].is_valid_node_name_option?

      nodes.each do |n|
        puts("Beginning ssh run for #{ n.name } (#{ n.public_ipaddress })") unless @options['quiet']

        start_ssh_session(n.public_ipaddress)
      end

      @config['auditor'].notify_slack_on_completion("ssh run completed on #{ @options['node_name'] } (#{ nodes.first.public_ipaddress })\n") if @config['cheftacular']['auditing']
    end

    private

    def start_ssh_session ip_address
      `ssh #{ Cheftacular::SSH_INLINE_VARS } -t #{ @config['cheftacular']['deploy_user'] }@#{ ip_address } > /dev/tty`
    end
  end
end
