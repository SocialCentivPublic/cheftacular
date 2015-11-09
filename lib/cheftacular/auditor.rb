
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
      ret_hash['command']   = @options['command']
      
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

    def compile_audit_hash_entry_as_array audit_hash, entry_number=0, ret_array=[]
      ret_array << "#{ (entry_number + '. ') unless entry_number == 0 }#{ audit_hash['command'] }"
      ret_array << "  Hostname:  #{ audit_hash['hostname'] }"
      ret_array << "  Arguments: #{ audit_hash['arguments'] }"       unless audit_hash['arguments'].empty?
      ret_array << "  Options:   #{ audit_hash['options'].to_hash }" unless audit_hash['options'].empty?
      
      ret_array = ret_array.map { |entry| entry.prepend('    ')} unless entry_number == 0

      ret_array
    end

    private

    def audit_command_to_slack_queue audit_hash, msg=''
      msg << compile_audit_hash_entry_as_array(audit_hash).join("\n")

      @config['slack_queue'] << { message: msg.prepend('```').insert(-1, '```'), channel: @config['cheftacular']['slack']['notify_on_command_execute'] }
    end
  end
end
