
class Cheftacular
  class StatelessActionDocumentation
    def cheftacular_yml_help
      @config['documentation']['stateless_action'] <<  [
        "`cft cheftacular_yml_help KEY` this command" +
        "allows you to get help on the meaning of each key in your cheftacular.yml overall config.",

        [
          "    1. This command can also by run with `cft yaml_help`."
        ]
      ]

      @config['documentation']['application'] << @config['documentation']['stateless_action'].last
    end
  end

  class StatelessAction
    def cheftacular_yml_help command=''

    end

    alias_method :yaml_help, :cheftacular_yml_help

    private
  end
end
