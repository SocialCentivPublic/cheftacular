#refresh the authorized_keys in the authentication data bag from the chef server
class Cheftacular
  class StatelessActionDocumentation
    def add_ssh_key_to_bag
      @config['documentation']['stateless_action'] <<  [
        "`cft add_ssh_key_to_bag \"<NEW SSH PUB KEY>\" [SPECIFIC_REPOSITORY]` this command will add the given ssh key to the default authentication data bag. " +
        "After this your server recipes should read the contents of the 'default' 'authentication' bag for the authorized_keys array.",

        [
          "    1. `SPECIFIC_REPOSITORY` is a special argument, if left blank the key will be placed in the authorized_keys array in the bag, otherwise it will " +
          "be placed in the specific_authorized_keys hash under a key named for the repository that is passed. The script will error if SPECIFIC_REPOSITORY " +
          "does not exist in the cheftacular.yml respositories hash. You can then use this data to give users selective ssh access to certain servers."
        ]
      ]
    end
  end

  class StatelessAction
    #TODO key for environment specific deploys?
    def add_ssh_key_to_bag specific_repository=""
      raise "This action can only be performed if the mode is set to devops" unless @config['helper'].running_in_mode?('devops')
      
      raise "Please put quotes around your SSH public key!" if ARGV[1].length < 25 #TODO REFACTOR to accurate length of shortest key

      specific_repository = ARGV[2] if ARGV[2] && specific_repository.empty?
      
      if !specific_repository.empty? && @config['getter'].get_repo_names_for_repositories.include?(specific_repository)
        puts "The repository passed (#{ specific_repository }) is not listed in the cheftacular.yml repositories hash! Please update the hash or check your spelling!"

        return false
      end

      public_ssh_key = ARGV[1]

      if specific_repository.blank?
        @config['default']['authentication_bag_hash']["authorized_keys"] << public_ssh_key
      else
        @config['default']['authentication_bag_hash']["specific_authorized_keys"] << public_ssh_key
      end

      @config['ChefDataBag'].save_authentication_bag
    end
  end
end
