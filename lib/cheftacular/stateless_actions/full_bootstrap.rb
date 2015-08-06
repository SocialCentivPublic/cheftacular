
class Cheftacular
  class StatelessActionDocumentation
    def full_bootstrap
      @config['documentation']['stateless_action'] <<  [
        "`cft full_bootstrap ADDRESS ROOT_PASS NODE_NAME` This command performs both " +
        "#{ @config['cheftacular']['preferred_cloud_os'] }_bootstrap and chef_bootstrap."
      ]
    end
  end

  class StatelessAction
    def full_bootstrap
      raise "This action can only be performed if the mode is set to devops" if !@config['helper'].running_in_mode?('devops') && !@options['in_scaling']

      @options['address']     = ARGV[1] unless @options['address']
      @options['client_pass'] = ARGV[2] unless @options['client_pass']
      @options['node_name']   = ARGV[3] unless @options['node_name']

      case @config['cheftacular']['preferred_cloud_os']
      when 'ubuntu' || 'debian' then @config['stateless_action'].ubuntu_bootstrap
      else                           @config['stateless_action'].instance_eval("#{ @config['cheftacular']['preferred_cloud_os'] }_bootstrap")
      end

      @config['initializer'].initialize_passwords @options['env'] #reset the passwords var to contain the new deploy pass set in ubuntu_bootstrap

      @config['helper'].install_rvm_sh_file if @config['cheftacular']['install_rvm_on_boot']

      @config['stateless_action'].chef_bootstrap
    end
  end
end
