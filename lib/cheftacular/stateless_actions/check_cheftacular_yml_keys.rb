
class Cheftacular
  class StatelessActionDocumentation
    def check_cheftacular_yml_keys
      @config['documentation']['stateless_action'] <<  [
        "`cft check_cheftacular_yml_keys` allows you to check to see if your cheftacular yml keys are valid to the current version of cheftacular. " +
        "It will also set your missing keys to their likely default and let you know to update the cheftacular.yml file."
      ]
    end
  end

  class StatelessAction
    def check_cheftacular_yml_keys out=[], exit_on_missing=false, warn_on_missing=false
      base_message = "Your cheftacular.yml is missing the key KEY, its default value is being set to DEFAULT for this run."

      #############################2.7.0################################################

      unless @config['cheftacular'].has_key?('backup_config')
        #backup_config:global_backup_role_name
        base_message.gsub('KEY', 'backup_config').gsub('DEFAULT', 'nil')

        warn_on_missing = true
      end

      #############################2.6.0################################################
      unless @config['cheftacular'].has_key?('route_dns_changes_via')
        puts base_message.gsub('KEY', 'route_dns_changes_via').gsub('DEFAULT', @options['preferred_cloud'])

        @config['cheftacular']['route_dns_changes_via'] = @options['preferred_cloud']

        warn_on_missing = true
      end

      unless @config['cheftacular'].has_key?('node_name_separator')
        puts base_message.gsub('KEY', 'node_name_separator').gsub('DEFAULT', '-')

        @config['cheftacular']['node_name_separator'] = '-'

        warn_on_missing = true
      end

      unless @config['cheftacular'].has_key?('cloud_authentication')
        puts (base_message.gsub('KEY', 'cloud_authentication').split(',').first + ', this is a critical issue and must be fixed.')

        exit_on_missing = true
      end

      if !@config['cheftacular'].has_key?('chef_server') && @options['command'] == 'chef_server'
        puts (base_message.gsub('KEY', 'chef_server').split(',').first + ', this is a critical issue and must be fixed to run the chef_server command.')

        exit_on_missing = true
      end

      unless @config['cheftacular'].has_key?('chef_version')
        puts (base_message.gsub('KEY', 'chef_version').split(',').first + ', this is a critical issue and must be fixed.')

        exit_on_missing = true
      end

      unless @config['cheftacular'].has_key?('pre_install_packages')
        puts base_message.gsub('KEY', 'pre_install_packages').gsub('DEFAULT', '')

        @config['cheftacular']['pre_install_packages'] = ''

        warn_on_missing = true
      end

      unless @config['cheftacular'].has_key?('role_toggling')
        puts base_message.gsub('KEY', 'role_toggling').gsub('DEFAULT', "it's default nested keys")

        @config['cheftacular']['role_toggling'] = {}
        @config['cheftacular']['role_toggling']['deactivated_role_suffix'] = '_deactivated'
        @config['cheftacular']['role_toggling']['strict_roles']            = true
        @config['cheftacular']['role_toggling']['skip_confirm']            = false
        @config['cheftacular']['role_toggling']['do_not_allow_toggling']   = true

        warn_on_missing = true
      end

      if warn_on_missing || exit_on_missing
        puts "Please enter your missing keys into your cheftacular.yml based off of the cheftacular.yml at"
        puts "\n  https://github.com/SocialCentivPublic/cheftacular/blob/master/examples/cheftacular.yml"
      end

      exit if exit_on_missing || @options['command'] == __method__
    end
  end
end
