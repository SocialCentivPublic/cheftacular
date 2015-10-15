class Cheftacular
  class StatelessActionDocumentation
    def initialize_cheftacular_yml
      @config['documentation']['stateless_action'][__method__] ||= {}
      @config['documentation']['stateless_action'][__method__]['long_description'] = [
        "`cft initialize_cheftacular_yml [application|TheCheftacularCookbook]` will create a cheftacular.yml " +
        "file in your config folder (and create the config folder if it does not exist). If you already have a cheftacular.yml file " +
        "in the config folder, it will create a cheftacular.example.yml file that will contain the new changes / keys in the latest " +
        "cheftacular version.",

        [
          "    1. If `TheCheftacularCookbook` is passed, the generated cheftacular.yml file will include the additional TheCheftacularCookbook keys.",

          "    2. If `application` is passed, the generated cheftacular.yml file will look like one you could use in an application directory."
        ]
      ]

      @config['documentation']['stateless_action'][__method__]['short_description'] = 'Sets up a cheftacular.yml file or a cheftacular.yml.example file'
    end
  end

  class InitializationAction
    def initialize_cheftacular_yml
      
    end
  end

  class StatelessAction
    def initialize_cheftacular_yml example_file_to_load='cheftacular.yml'
      example_file_to_load = 'thecheftacularcookbook.cheftacular.yml' if ARGV[1] == 'TheCheftacularCookbook'
      example_file_to_load = 'application.cheftacular.yml'            if ARGV[1] == 'application'

      FileUtils.mkdir_p(File.join(@config['locs']['chef-repo'], "config"))

      if File.exist?(File.join(@config['locs']['chef-repo'], "config", "cheftacular.yml"))
        @config['helper'].write_config_cheftacular_yml_file('cheftacular.example.yml', example_file_to_load )
      else
        @config['helper'].write_config_cheftacular_yml_file('cheftacular.yml', example_file_to_load)
      end
    end
  end
end
