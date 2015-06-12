class Cheftacular
  class StatelessActionDocumentation
    def ubuntu_bootstrap
      @config['documentation']['stateless_action'] <<  [
        "`cft ubuntu_bootstrap ADDRESS ROOT_PASS` This command will bring a fresh server to a state " +
        "where chef-client can be run on it via `cft chef-bootstrap`. It should be noted that it is in "+
        "this step where a server's randomized deploy_user sudo password is generated."
      ]
    end
  end

  class StatelessAction
    def ubuntu_bootstrap out=[]
      raise "This action can only be performed if the mode is set to devops" if !@config['helper'].running_in_mode?('devops') && !@options['in_scaling']

      @options['address']     = ARGV[1] unless @options['address']
      @options['client_pass'] = ARGV[2] unless @options['address']

      if `which sshpass`.empty?
        raise "sshpass not installed! Please run brew install https://raw.github.com/eugeneoden/homebrew/eca9de1/Library/Formula/sshpass.rb (or get it from your repo for linux)"
      end

      new_deploy_pass = @config['helper'].gen_pass(@config['cheftacular']['server_pass_length'])

      deploy_user = @config['cheftacular']['deploy_user']

      root_commands = [
        "cd /home",
        "adduser #{ deploy_user } --gecos \",,,,\" --disabled-password",
        "echo #{ deploy_user }:#{ new_deploy_pass } | chpasswd",
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

      sudo = "echo #{ new_deploy_pass } | sudo -S"

      deploy_commands = [
        "#{ sudo } apt-get update",
        "#{ sudo } apt-get install curl git-core shorewall -y",
        "#{ sudo } apt-get upgrade -y"
      ]

      final_commands = []

      if @config['cheftacular']['install_rvm_on_boot']
        deploy_commands << "gpg --keyserver hkp://keys.gnupg.net --recv-keys #{ @config['cheftacular']['rvm_gpg_key'] }"
        deploy_commands << "curl -L https://get.rvm.io | bash -s stable"

        final_commands

        rvm_source = "source /home/deploy/.rvm/bin/rvm &&"

        final_commands = [
          "#{ rvm_source } echo '#{ new_deploy_pass }' | rvmsudo -S rvm requirements",
          "#{ rvm_source } rvm install #{ @config['cheftacular']['ruby_version'] }",
          "#{ rvm_source } rvm install 1.9.3-p327" #chef's default ruby, we'll need it in a place rvm can find it until the symlink is made 
        ]
      end

      out << `sshpass -p "#{ @options['client_pass'] }" ssh -t -oStrictHostKeyChecking=no root@#{ @options['address'] } '#{ root_commands.join(' && ') } && service ssh restart'`

      puts("Finished initial setup...stage 1 of 3 for server #{ @options['address'] }") if @options['in_scaling']

      puts(out.last) unless @options['quiet'] || @options['in_scaling']

      deploy_commands.each do |cmnd|
        puts("(#{ @options['address'] }) Running #{ cmnd.gsub("#{ new_deploy_pass }", "sudo password") }") unless @options['quiet'] || @options['in_scaling']
        out << `ssh -t -oStrictHostKeyChecking=no #{ deploy_user }@#{ @options['address'] } "#{ cmnd }"`

        puts(out.last) unless @options['quiet'] || @options['in_scaling']
      end

      puts("Finished deploy setup....stage 2 of 3 for server #{ @options['address'] }") if @options['in_scaling']

      final_commands.each do |cmnd|
        puts "(#{ @options['address'] }) Running #{ cmnd.gsub("#{ new_deploy_pass }", "sudo password") }"
        out << `ssh -t -oStrictHostKeyChecking=no #{ deploy_user }@#{ @options['address'] } "#{ cmnd }"`

        puts(out.last) unless @options['quiet'] || @options['in_scaling']
      end

      puts("Finished ruby setup......stage 3 of 3 for server #{ @options['address'] }") if @options['in_scaling']

      @config[@options['env']]['server_passwords_bag_hash']["#{ @options['address'] }-root-pass"] = @options['client_pass']

      @config[@options['env']]['server_passwords_bag_hash']["#{ @options['address'] }-deploy-pass"] = new_deploy_pass

      @config[@options['env']]['server_passwords_bag_hash']["#{ @options['address'] }-name"] = @options['node_name'] if @options['node_name']

      @config['ChefDataBag'].save_server_passwords_bag unless @options['in_scaling']
    end
  end
end
