
class Cheftacular
  class StatelessActionDocumentation
    def cheftacular_config
      @config['documentation']['stateless_action'][__method__] ||= {}
      @config['documentation']['stateless_action'][__method__]['long_description'] = [
        "`cft cheftacular_config [diff|display|sync|overwrite]` this command " +
        "Allows you to interact with your complete cheftacular configuration, the union of all repository's cheftacular.ymls. ",

        [
          "    1. `display` will show the current overall configuration for cheftacular.",

          "    2. `diff` will show the difference between your current cheftacular.yml and the server's. Run automatically on a sync.",

          "    3. `sync` will sync your local cheftacular yaml keys ONTO the server's keys. Will send a slack notification " +
          "if slack is configured (the slack notification contains the diffed keys). The sync only occurs if there are CHANGES to the file.",

          "    4. This command is aliased to `cc`"
        ]
      ]

      @config['documentation']['stateless_action'][__method__]['short_description'] = 'Allows you to see the overall cheftacular config or force a sync'

      @config['documentation']['application'][__method__] = @config['documentation']['stateless_action'][__method__]
    end
  end

  class StatelessAction
    def cheftacular_config command=''
      command = ARGV[1] if command.blank?

      raise "Unsupported command (#{ command }) for cft cheftacular_config" unless command =~ /diff|display|sync|overwrite/

      self.send("cheftacular_config_#{ command }")
    end

    alias_method :cc, :cheftacular_config

    private

    def cheftacular_config_display
      ap(@config['cheftacular'], {indent: 2})
    end

    def cheftacular_config_diff
      @config['helper'].display_cheftacular_config_diff
    end

    def cheftacular_config_sync
      @config['default']['cheftacular_bag_hash'] = @config['cheftacular'].deep_dup.except('default_repository', 'mode') #the values have already been merged

      @config['ChefDataBag'].save_cheftacular_bag
    end
  end
end
