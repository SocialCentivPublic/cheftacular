
class Cheftacular
  class StatelessActionDocumentation
    def cheftacular_config
      @config['documentation']['stateless_action'] <<  [
        "`cft cheftacular_config [display|sync|overwrite]` this command " +
        "Allows you to interact with your complete cheftacular configuration, the union of all repository's cheftacular.ymls. ",

        [
          "    1. `display` will show the current overall configuration for cheftacular.",

          "    2. `sync` will sync your local cheftacular yaml keys ONTO the server's keys. This happens automatically whenever a " +
          "difference is detected between the local keys and the remote keys but can be run manually. Will send a slack notification " +
          "if slack is configured (the slack notification contains the diffed keys)."
        ]
      ]

      @config['documentation']['application'] << @config['documentation']['stateless_action'].last
    end
  end

  class StatelessAction
    def cheftacular_config command=''
      command = ARGV[1] if command.blank?

      raise "Unsupported command (#{ command }) for cft cheftacular_config" unless command =~ /display|sync|overwrite/

      self.send("cheftacular_config_#{ command }")
    end

    private

    def cheftacular_config_display
      ap(@config['cheftacular'], {indent: 2})
    end

    def cheftacular_config_sync
      parsed_cheftacular = Digest::SHA2.hexdigest(@config['helper'].get_cheftacular_yml_as_hash.to_s)

      return true if File.exist?(@config['filesystem'].current_local_cheftacular_file_cache_path) && File.read(@config['filesystem'].current_local_cheftacular_file_cache_path) == parsed_cheftacular

      @config['default']['cheftacular_bag_hash'] = @config['cheftacular'].deep_dup.except('default_repository', 'mode') #the values have already been merged

      @config['ChefDataBag'].save_cheftacular_bag

      puts "Creating file cache for #{ Time.now.strftime("%Y%m%d") }'s local cheftacular.yml."

      @config['filesystem'].write_local_cheftacular_cache_file parsed_cheftacular
    end
  end
end
