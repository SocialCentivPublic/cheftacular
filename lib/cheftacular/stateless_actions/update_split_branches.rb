
class Cheftacular
  class StatelessActionDocumentation
    def update_split_branches
      @config['documentation']['stateless_action'] <<  [
        "`cft update_split_branches` will perform a series of git commands that will merge all the " +
        "split branches for your split_branch enabled repositories with what is currently on master and push them.",

        [
          "    1. Repository must be set with `-R REPOSITORY_NAME` for this command to work.",

          "    2. Attempting to run this command in other repositories that do not have the branches listed " +
          "in run_list_environments OR do not have split_branch set to true will raise an error.",

          "    3. This command will only succeed *IF THERE ARE NO MERGE CONFLICTS*.",

          "    4. This command will return a helpful error statement if you attempt to run the command " + 
          "with changes to your current working directory. You must commit these changes before running this command."
        ]
      ]
    end
  end

  class StatelessAction
    def update_split_branches
      target_loc = @config['helper'].running_in_mode?('application') ? @config['locs']['app-root'] : "#{ @config['locs']['root'] }/#{ @options['repository'] }"

      current_revision = `cd #{ target_loc } && git rev-parse --abbrev-ref HEAD`
      
      puts "Preparing to run merges..."

      split_branch_repos =  @config['getter'].get_split_branch_hash

      raise "unsupported codebase, please run in #{ split_branch_repos.keys.join(', ') } only!" if ( @options['repository'] =~ /#{ split_branch_repos.keys.join('|') }/ ) == 0

      test_for_changes = `cd #{ target_loc } && git diff --exit-code`

      unless test_for_changes.empty?
        puts "You have changes in your current working tree for #{ target_loc }. Please commit these changes before running this command."

        exit
      end

      commands = [
        "cd #{ target_loc }",
        "git checkout master",
        "git pull origin master",
        "git fetch origin",
      ]

      @config['run_list_environments'].each_pair do |env, branch_hash|
        branch_hash.keys.each do |branch_name|        
          true_branch_name = branch_name.gsub('_','-')

          commands << ["git checkout #{ true_branch_name }", "git pull origin #{ true_branch_name }", 'git merge master --no-edit', "git push origin #{ true_branch_name }"]
        end
      end

      commands << "git checkout #{ current_revision }"

      puts `#{ commands.flatten.join(' && ') }` unless @options['quiet']

      puts "Update split branches complete. You have been returned to the branch you were on before which was \"#{ current_revision.chomp }\"."
    end
  end
end
