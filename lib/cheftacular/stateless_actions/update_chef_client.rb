
class Cheftacular
  class StatelessActionDocumentation
    def update_chef_client
      @config['documentation']['stateless_action'] <<  [
        "[NYI]`cft update_chef_client` attempts to update the chef-client of all nodes to the latest version. " +
        "Should be done with caution and with the chef_server's version in mind."
      ]
    end
  end

  class StatelessAction
    def update_chef_client
      raise "Not Yet Implemented"
      raise "This action can only be performed if the mode is set to devops" unless @config['helper'].running_in_mode?('devops')
    end
  end
end