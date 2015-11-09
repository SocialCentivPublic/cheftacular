class Cheftacular
  class StatelessActionDocumentation
    def get_active_ssh_connections
      @config['documentation']['stateless_action'][__method__] ||= {}
      @config['documentation']['stateless_action'][__method__]['long_description'] = [
        "[NYI]`cft get_active_ssh_connections` will fetch the active ssh connections from every server and output it into your log directory."
      ]

      #@config['documentation']['application'][__method__] = @config['documentation']['stateless_action'][__method__]
    end
  end

  class StatelessAction
    def get_active_ssh_connections
      # netstat -atn | grep ':22'
      raise "Not yet implemented"
    end
  end
end
