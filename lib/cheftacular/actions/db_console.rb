class Cheftacular
  class ActionDocumentation
    def db_console
      @config['documentation']['action'] <<  [
        "`cft db_console` " +
        "will create a database console session on the first node found for a database stack in the current environment.",

        [
          "    1. This command is aliased to psql, typing `cft psql` will drop you into a rails stack database psql session.",

          "    2. This command is also aliased to mongo, typing `cft mongo` will drop you into a mongodb mongo session."
        ]
      ]
    end
  end

  class Action
    def db_console
      self.send("db_console_#{ @config['getter'].get_current_database }")
    end

    def db_console_postgresql
      nodes = @config['getter'].get_true_node_objects(true)

      #must have rails stack to run migrations and not be a db, only want ONE node
      psqlable_nodes = @config['parser'].exclude_nodes( nodes, [{ unless: "role[#{ @options['role'] }]" }, { unless: 'role[rails]' }, { if: { not_env: @options['env'] } }], true )

      database_host  = @config['parser'].exclude_nodes( nodes, [{ unless: "role[#{ @config['getter'].get_current_repo_config['db_primary_host_role'] }]"}, { if: { not_env: @options['env'] } }], true).first

      private_database_host_address = @config['getter'].get_address_hash(database_host.name)[database_host.name]['priv']

      psqlable_nodes.each do |n|
        puts("Beginning database console run for #{ n.name } (#{ n.public_ipaddress }) on role #{ @options['role'] }") unless @options['quiet']

        start_console_postgresql(n.public_ipaddress, private_database_host_address )
      end
    end

    def db_console_mongodb
      nodes = @config['getter'].get_true_node_objects(true)

      #must have mongo db, only want ONE node
      mongoable_nodes = @config['parser'].exclude_nodes( nodes, [{ unless: "role[#{ @options['role'] }]" }, { if: { not_env: @options['env'] } }], true )

      mongoable_nodes.each do |n|
        puts("Beginning database console run for #{ n.name } (#{ n.public_ipaddress }) on role #{ @options['role'] }") unless @options['quiet']

        start_console_mongodb(n.public_ipaddress)
      end
    end

    def db_console_mysql
      raise "Not yet implemented"
    end

    def db_console_none
      raise "You attempted to create a database console for a role that had no database type attached to it, this is not possible."
    end

    def db_console_
      puts "db_console method tried to create a db_console for the role \"#{ @options['role'] }\" but it doesn't appear to have a repository set! Skipping..."

      return false
    end

    alias_method :psql, :db_console_postgresql
    alias_method :mongo, :db_console_mongodb
    private 

    def start_console_postgresql ip_address, database_host
      pg_pass   = @config[@options['env']]['chef_passwords_bag_hash'][@options['repository']]['pg_pass'] if @config[@options['env']]['chef_passwords_bag_hash'][@options['repository']].has_key?('pg_pass') 
      pg_pass ||= @config[@options['env']]['chef_passwords_bag_hash']['pg_pass']
      db_user   = @config['getter'].get_current_repo_config['application_database_user']
      db_name   = if @config['getter'].get_current_repo_config.has_key?('custom_database_name')
                    @config['getter'].get_current_repo_config['custom_database_name']
                  else
                    "#{ @config['getter'].get_current_repo_config['repo_name'] }_#{ @options['env'] }"
                  end

      #the >/dev/tty after the ssh block redirects the full output to stdout, not /dev/null where it normally goes  
      `ssh -oStrictHostKeyChecking=no -tt #{ @config['cheftacular']['deploy_user'] }@#{ ip_address } "PGPASSWORD=#{ pg_pass } psql -U #{ db_user } -h #{ database_host } -d #{ db_name }" > /dev/tty`
    end

    def start_console_mongodb ip_address
      #the >/dev/tty after the ssh block redirects the full output to stdout, not /dev/null where it normally goes
      #TODO refactor to more general solution (path / port)
      `ssh -oStrictHostKeyChecking=no -tt #{ @config['cheftacular']['deploy_user'] }@#{ ip_address } "mongo localhost:27017/mongodb" > /dev/tty`
    end

    def start_console_mysql
      raise "Not yet implemented"
    end
  end
end
