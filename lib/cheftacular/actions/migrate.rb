class Cheftacular
  class ActionDocumentation
    def migrate
      @config['documentation']['action'][__method__] ||= {}
      @config['documentation']['action'][__method__]['long_description'] = [
        "`cft migrate` this command will grab the first alphabetical node for a repository " +
        "and run a migration that will hit the database primary server.",

        [
          "    1. Currently only supports rails stacks."
        ]
      ]

      @config['documentation']['action'][__method__]['short_description'] = 'Creates a database migration on the current environment'
    end
  end

  class Action
    def migrate nodes=[]
      self.send("migrate_#{ @config['getter'].get_current_stack }", nodes)
    end

    def migrate_ruby_on_rails nodes=[]
      nodes = @config['getter'].get_true_node_objects if nodes.empty?

      #must have rails stack to run migrations, only want ONE node
      nodes = @config['parser'].exclude_nodes(nodes, [{ unless: "role[#{ @options['role'] }]" }, { unless: 'role[rails]' }], true)

      logs_bag_hash = run_ruby_on_rails('rake db:migrate', __method__.to_s, ['return_logs_bag_hash'], nodes)

      if logs_bag_hash["#{ nodes.first.name }-#{ __method__ }"]['text'].empty? || 
        ( cheftacular['repositories'][options['role']].has_key?('not_a_migration_message') && logs_bag_hash["#{ nodes.first.name }-#{ __method__ }"]['text'] == cheftacular['repositories'][options['role']]['not_a_migration_message'] )

        puts("Nothing to migrate for #{ options['role'] }...")
      end

      @config['helper'].send_log_bag_hash_slack_notification(logs_bag_hash, __method__, 'Failing migration detected, please fix this and deploy again, exiting...')

      @options['run_migration_already'] = true

      #restart the servers again after a deploy with a migration just in case
      if !log_data.empty? && log_data != @config['cheftacular']['repositories'][@options['role']]['not_a_migration_message']
        @config['auditor'].notify_slack_on_completion("migrate run completed on #{ nodes.map { |node| node.name }.join(', ') }\n") if @config['cheftacular']['auditing']

        @config['action'].deploy
      end
    end

    def migrate_wordpress nodes=[]
      puts("Method #{ __method__ } is not yet implemented") if @options['verbose']

      return false
    end

    def migrate_nodejs nodes=[]
      puts("Method #{ __method__ } is not yet implemented") if @options['verbose']

      return false
    end

    def migrate_all nodes=[]
      raise "You attempted to migrate the all role, this is not possible."
    end

    def migrate_ nodes=[]
      puts("Migrate method tried to migrate the role \"#{ @options['role'] }\" but it doesn't appear to have a repository set! Skipping...") if @options['verbose']

      return false
    end
  end
end
