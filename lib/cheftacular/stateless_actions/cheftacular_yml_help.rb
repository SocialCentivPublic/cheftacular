
class Cheftacular
  class StatelessActionDocumentation
    def cheftacular_yml_help
      @config['documentation']['stateless_action'][__method__] ||= {}
      @config['documentation']['stateless_action'][__method__]['long_description'] = [
        "[NYI]`cft cheftacular_yml_help KEY` this command" +
        "allows you to get help on the meaning of each key in your cheftacular.yml overall config.",

        [
          "    1. This command can also by run with `cft yaml_help`."
        ]
      ]

      @config['documentation']['stateless_action'][__method__]['short_description'] = '[NYI]Gives help on the keys in your cheftacular.yml'

      @config['documentation']['application'][__method__] = @config['documentation']['stateless_action'][__method__]
    end
  end

  class StatelessAction
    def cheftacular_yml_help command=''
      raise "Not Yet Implemented"

    end

    alias_method :yaml_help, :cheftacular_yml_help

    private
  end
end
