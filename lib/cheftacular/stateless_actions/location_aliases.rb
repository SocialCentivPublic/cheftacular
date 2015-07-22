class Cheftacular
  class StatelessActionDocumentation
    def location_aliases
      @config['documentation']['stateless_action'] <<  [
        "`cft location_aliases` will list all location aliases listed in your cheftacular.yml. These aliases can be used " +
        "in the `cft file` command."
      ]

      @config['documentation']['application'] << @config['documentation']['stateless_action'].last
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
