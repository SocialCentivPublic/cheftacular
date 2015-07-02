class Cheftacular
  class StatelessActionDocumentation
    def get_active_ssh_connections
      @config['documentation']['stateless_action'] <<  [
        "[NYI]`cft get_active_ssh_connections` will fetch the active ssh connections from every server and output it into your log directory."
      ]

      @config['documentation']['application'] << @config['documentation']['stateless_action'].last
    end
  end

  class StatelessAction
    def get_active_ssh_connections
      # netstat -atn | grep ':22'
      raise "Not yet implemented"
    end
  end
end
