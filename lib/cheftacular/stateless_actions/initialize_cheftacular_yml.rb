class Cheftacular
  class StatelessActionDocumentation
    def initialize_cheftacular_yml
      @config['documentation']['stateless_action'] <<  [
        "`cft initialize_cheftacular_yml` will create a cheftacular.yml file in your config folder (and create the" +
        "config folder if it does not exist). If you already have a cheftacular.yml file in the config folder, it will " +
        "create a cheftacular.yml.example file that will contain the new changes / keys in the latest cheftacular version."
      ]
    end
  end

  class InitializationAction
    def initialize_cheftacular_yml
      
    end
  end

  class StatelessAction
    def initialize_cheftacular_yml
      #TODO
    end
  end
end
