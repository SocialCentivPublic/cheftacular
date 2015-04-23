
class Cheftacular
  class StatelessActionDocumentation
    def get_pg_pass
      @config['documentation']['stateless_action'] <<  [
        "`cft get_pg_pass ['clip']` command will output the current environment's pg_password to your terminal. " +
        "Optionally you can pass in clip like `cft get_pg_pass clip` to have it also copy the pass to your clipboard."
      ]

      @config['documentation']['application'] << @config['documentation']['stateless_action'].last
    end
  end

  class StatelessAction
    def get_pg_pass clip=false, target_repos=[]

      @config['parser'].parse_role(@options['role'])

      clip = ARGV[1] == 'clip'
    
      if @options['role']
        target_repos << @config['cheftacular']['repositories'][@options['role']]
      else
        @config['cheftacular']['repositories'].each_pair do |short_repo_name, repo_hash|
          target_repos << repo_hash if repo_hash['database'] == 'postgresql'
        end
      end

      target_repos.each do |repo_hash|
        db_user  = repo_hash['application_database_user']
        database = repo_hash.has_key?('custom_database_name') ? repo_hash['custom_database_name'] : repo_hash['repo_name']
        password = @config[@options['env']]['chef_passwords_bag_hash']['pg_pass']

        ap @config[@options['env']]['chef_passwords_bag_hash']

        if @config[@options['env']]['chef_passwords_bag_hash'].has_key?(repo_hash['repo_name']) && @config[@options['env']]['chef_passwords_bag_hash'][repo_hash['repo_name']].has_key?('pg_pass')
          password = @config[@options['env']]['chef_passwords_bag_hash'][repo_hash['repo_name']]['pg_pass'] unless @config[@options['env']]['chef_passwords_bag_hash'][repo_hash['repo_name']]['pg_pass'].empty?
        end
        
        puts "postgres password for user #{ db_user } in database #{ database }_#{ @options['env'] } is #{ password }"
      end

      if clip && target_repos.count == 1
        case CONFIG['host_os']
        when /mswin|windows/i
          raise "#{ __method__ } does not support this operating system at this time"
        when /linux|arch/i
          raise "#{ __method__ } does not support this operating system at this time"
        when /sunos|solaris/i
          raise "#{ __method__ } does not support this operating system at this time"
        when /darwin/i
          `echo '#{ password }' | pbcopy`
        else
          raise "#{ __method__ } does not support this operating system at this time"
        end
      elsif clip && target_repos.count > 1
        puts "Unable to insert database string into clipboard, please copy paste as normal"
      end
    end
  end
end
