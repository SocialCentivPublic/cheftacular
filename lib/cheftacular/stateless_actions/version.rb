
class Cheftacular
  class StatelessActionDocumentation
    def version
      @config['documentation']['stateless_action'][__method__] ||= {}
      @config['documentation']['stateless_action'][__method__]['long_description'] = [
        "`cft version` this command prints out the current version of cheftacular.",

        [
          "    1. Aliased to `cft v`"
        ]
      ]

      @config['documentation']['stateless_action'][__method__]['short_description'] = 'Displays the current version of cheftacular'

      @config['documentation']['application'][__method__] = @config['documentation']['stateless_action'][__method__]
    end
  end

  class InitializationAction
    def version
      
    end
  end

  class StatelessAction
    def version
      @config['helper'].display_currently_installed_version
    end

    alias_method :v, :version
  end
end
