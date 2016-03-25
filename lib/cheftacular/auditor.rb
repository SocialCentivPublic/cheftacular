
class Cheftacular
  class Auditor
    def initialize options, config
      @options, @config = options, config
    end

    def audit_run
      current_day  = Time.now.strftime('%Y%m%d')
      current_time = Time.now.strftime('%H:%M')

      audit_data = audit_run_as_hash

      @config[@options['env']]['audit_bag_hash']['audit_log'][current_day] ||= {}
      @config[@options['env']]['audit_bag_hash']['audit_log'][current_day][current_time] ||= []
      @config[@options['env']]['audit_bag_hash']['audit_log'][current_day][current_time] << audit_data

      @config['ChefDataBag'].save_audit_bag

      audit_command_to_slack_queue(audit_data) unless @config['cheftacular']['slack']['notify_on_command_execute'].blank?
    end

    def audit_run_as_hash ret_hash={}, options_to_ignore=[]
      ret_hash['hostname']  = Socket.gethostname
      ret_hash['directory'] = @config['locs']['root']
      ret_hash['version']   = Cheftacular::VERSION
      ret_hash['command']   = return_true_command(@options['command'])
      
      options_to_ignore << :preferred_cloud        if @options['preferred_cloud'] == @config['cheftacular']['preferred_cloud']
      options_to_ignore << :preferred_cloud_image  if @options['preferred_cloud_image'] == @config['cheftacular']['preferred_cloud_image']
      options_to_ignore << :preferred_cloud_region if @options['preferred_cloud_region'] == @config['cheftacular']['preferred_cloud_region']
      options_to_ignore << :virtualization_mode    if @options['virtualization_mode'] == @config['cheftacular']['virtualization_mode']
      options_to_ignore << :route_dns_changes_via  if @options['route_dns_changes_via'] == @config['cheftacular']['route_dns_changes_via']
      options_to_ignore << :sub_env
      options_to_ignore << :command

      ret_hash['options']   = @options.dup.delete_if { |key, value| options_to_ignore.include?(key.to_sym) }

      ret_hash['arguments'] = ARGV[1..ARGV.length]

      ret_hash
    end

    def compile_audit_hash_entry_as_array audit_hash, entry_number=0, mode='normal', ret_array=[], directory_content='', version_content=''
      directory_content = " (#{ audit_hash['directory'] })" if audit_hash.has_key?('directory')
      version_content   = " [#{ audit_hash['version'] }]"   if audit_hash.has_key?('version')

      ret_array << "#{ (entry_number.to_s + '. ') unless entry_number == 0 }#{ audit_hash['command'] }" if mode =~ /normal/
      ret_array << "  Hostname:  #{ audit_hash['hostname'] }#{ directory_content }#{ version_content }"

      if mode =~ /normal/
        ret_array << "  Arguments: #{ audit_hash['arguments'] }"       if !audit_hash['arguments'].nil? && !audit_hash['arguments'].empty?
        ret_array << "  Options:   #{ audit_hash['options'].to_hash }" unless audit_hash['options'].empty?
      end
      
      ret_array = ret_array.map { |entry| entry.prepend('    ')} unless entry_number == 0

      ret_array
    end

    def notify_slack_on_completion msg
      audit_command_to_slack_queue(audit_run_as_hash, 'short', msg)
    end

    def return_true_command command
      final_command = command

      if aliased_command_hash.values.flatten.include?(command)
        aliased_command_hash.each_pair do |full_command, alias_array|

          final_command = full_command if alias_array.include?(command)
        end
      end

      final_command
    end

    private

    def audit_command_to_slack_queue audit_hash, mode='normal', msg=''
      msg << compile_audit_hash_entry_as_array(audit_hash, 0, mode).join("\n")

      @config['slack_queue'] << { message: msg.prepend('```').insert(-1, '```'), channel: @config['cheftacular']['slack']['notify_on_command_execute'] }
    end

    def aliased_command_hash
      {
        check:                                            ['ch'],
        console:                                          ['co'],
        deploy:                                           ['d'],
        cheftacular_config:                               ['cc'],
        cheftacular_yml_help:                             ['yml_help'],
        client_list:                                      ['cl'],
        cloud_bootstrap:                                  ['cb'],
        environment:                                      ['e'],
        fix_known_hosts:                                  ['fkh'],
        knife_upload:                                     ['ku'],
        location_aliases:                                 ['la'],
        remove_client:                                    ['rc'],
        role_toggle:                                      ['rt'],
        update_cookbook:                                  ['uc'],
        update_the_cheftacular_cookbook_and_knife_upload: ['utcc', 'utccaku'],
        upload_nodes:                                     ['un'],
        upload_roles:                                     ['ur'],
        verify:                                           ['ve'],
        version:                                          ['v']
      }
    end
  end
end
