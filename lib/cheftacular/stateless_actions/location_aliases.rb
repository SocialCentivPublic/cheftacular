class Cheftacular
  class StatelessActionDocumentation
    def location_aliases
      @config['documentation']['stateless_action'][__method__] ||= {}
      @config['documentation']['stateless_action'][__method__]['long_description'] = [
        "`cft location_aliases` will list all location aliases listed in your cheftacular.yml. These aliases can be used " +
        "in the `cft file` command."
      ]

      @config['documentation']['stateless_action'][__method__]['short_description'] = 'Checks your location aliases that can be used with the cft file command'

      @config['documentation']['application'][__method__] = @config['documentation']['stateless_action'][__method__]
    end
  end

  class InitializationAction
    def location_aliases
      
    end
  end

  class StatelessAction
    def location_aliases
      ap @config['cheftacular']['location_aliases']
    end
  end
end
