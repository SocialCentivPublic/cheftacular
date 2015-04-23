
#Uploads a private key found in ~/.ssh/id_rsa to an encrypted bag to let the chef-server access private repos.
class Cheftacular
  class StatelessActionDocumentation
    def create_git_key
      @config['documentation']['stateless_action'] <<  [
        "`cft create_git_key ID_RSA_FILE [OAUTH_TOKEN]` This command will update the default/authentication data bag with new credentials. " +
        "The [ID_RSA_FILE](https://help.github.com/articles/generating-ssh-keys) needs to exist beforehand.",

        [
          "    1. This command will upload both the private and public key to the data bag. " +
          "The public key should be the one that matches the github user for your deployment github user.",

          "    2. `OAUTH_TOKEN` *must* be generated by logging into github and generating an access token in the account settings -> applications -> personal access tokens"
        ]
      ]
    end
  end

  class StatelessAction
    def create_git_key oauth_key=""

      case ARGV[1]
      when nil      then raise "Too few arguments, please enter the filename of the id_rsa file you want to use"
      when 'id_rsa' then raise "Sorry, you can't use your default id_rsa"
      else               key_file = ARGV[1]
      end

      case ARGV[2]
      when nil then display_oauth_notice = true
      else          oauth_key = ARGV[2]
      end

      data = File.read("#{ @config['locs']['chef'] }/#{ key_file }")
      data_pub = File.read("#{ @config['locs']['chef'] }/#{ key_file }.pub")

      hash = @config['default']['authentication_bag_hash']

      if h.has_key?('private_key') 
        puts "Overwrite current git key in default data bag? (Y/y/N/n)"
        input = STDIN.gets.chomp

        overwrite = (input =~ /Y|y|yes/) == 0
      else overwrite = true
      end

      if overwrite

        hash['private_key'] = data

        hash['public_key'] = data_pub

        hash['OAuth'] = oauth_key

        @config['ChefDataBag'].save_authentication_bag

        if oauth_key.blank?
          puts "REMEMBER! You need to put a OAuth token into this data bag item!"
          puts "You need to go to github and get the auth_token for the hiplogiq deploy user!"
          puts "Copy the key and paste it inbetween the quotes.\n"
          puts "\"Oauth\": \"<PASTE YOUR OAUTH KEY HERE>\"\n\n"
          puts "Please run \nknife data bag edit default authentication --secret-file #{ @config['locs']['chef'] }/#{ @config['cheftacular']['data_bag_key_file'] }\n"
        end
      end
    end
  end
end