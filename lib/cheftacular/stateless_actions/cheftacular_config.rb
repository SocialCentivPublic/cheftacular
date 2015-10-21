
class Cheftacular
  class StatelessActionDocumentation
    def cheftacular_config
      @config['documentation']['stateless_action'][__method__] ||= {}
      @config['documentation']['stateless_action'][__method__]['long_description'] = [
        "`cft cheftacular_config [display|sync|overwrite]` this command " +
        "Allows you to interact with your complete cheftacular configuration, the union of all repository's cheftacular.ymls. ",

        [
          "    1. `display` will show the current overall configuration for cheftacular.",

          "    2. `diff` will show the difference between your current cheftacular.yml and the server's. Run automatically on a sync.",

          "    3. `sync` will sync your local cheftacular yaml keys ONTO the server's keys. Will send a slack notification " +
          "if slack is configured (the slack notification contains the diffed keys). The sync only occurs if there are CHANGES to the file."
        ]
      ]

      @config['documentation']['stateless_action'][__method__]['short_description'] = 'Allows you to see the overall cheftacular config or force a sync'

      @config['documentation']['application'][__method__] = @config['documentation']['stateless_action'][__method__]
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

    def cheftacular_config_diff
      diff_hash = @config['initial_cheftacular_yml'].deep_diff(@config['default']['cheftacular_bag_hash'], true).except('mode', 'default_repository').compact

      diff_hash.each_pair do |key, value|
        diff_hash.delete(key) if value.empty? || value.nil?
      end

      if @config['helper'].running_in_mode?('devops') && !diff_hash.empty?
        puts "Difference detected between local cheftacular.yml and data bag cheftacular.yml! Displaying..."

        ap diff_hash
      elsif @config['helper'].running_in_mode?('application') && @config['default']['cheftacular_bag_hash']['slack']['webhook'] && !diff_hash.empty?
        @config['slack_queue'] << diff_hash.awesome_inspect({plain: true, indent: 2}).prepend('```').insert(-1, '```')
      end
    end

    def cheftacular_config_sync
      cheftacular_config_diff

      parsed_cheftacular = Digest::SHA2.hexdigest(@config['helper'].get_cheftacular_yml_as_hash.to_s)

      return true if File.exist?(@config['filesystem'].local_cheftacular_file_cache_path) && File.read(@config['filesystem'].local_cheftacular_file_cache_path) == parsed_cheftacular

      @config['default']['cheftacular_bag_hash'] = @config['cheftacular'].deep_dup.except('default_repository', 'mode') #the values have already been merged

      @config['ChefDataBag'].save_cheftacular_bag

      puts "Creating file cache for #{ Time.now.strftime("%Y%m%d") }'s local cheftacular.yml."

      @config['filesystem'].write_local_cheftacular_cache_file parsed_cheftacular
    end
  end
end
