
class Cheftacular
  class StatelessActionDocumentation
    def clear_caches
      @config['documentation']['stateless_action'][__method__] ||= {}
      @config['documentation']['stateless_action'][__method__]['long_description'] = [
        "`cft clear_caches` this command allows you to clear all of your local caches.",

        [
          "    1. This command will force you to refetch all previously cached chef server data on the next `cft` run."
        ]
      ]

      @config['documentation']['stateless_action'][__method__]['short_description'] = 'Clears all cheftacular caches'

      @config['documentation']['application'][__method__] = @config['documentation']['stateless_action'][__method__]
    end
  end

  class InitializationAction
    def clear_caches
      
    end
  end

  class StatelessAction
    def clear_caches
      @config['filesystem'].cleanup_file_caches('all')
    end
  end
end
