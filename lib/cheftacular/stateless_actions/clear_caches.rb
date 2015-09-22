
class Cheftacular
  class StatelessActionDocumentation
    def clear_caches
      @config['documentation']['stateless_action'] <<  [
        "`cft clear_caches` this command allows you to clear all of your local caches.",
      ]

      @config['documentation']['application'] << @config['documentation']['stateless_action'].last
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
