class Cheftacular
  class StatelessActionDocumentation
    def compile_audit_log
      @config['documentation']['stateless_action'][__method__] ||= {}
      @config['documentation']['stateless_action'][__method__]['long_description'] = [
        "`cft compile_audit_log [clean]` compiles the audit logs in each environment's " +
        "audit data bag a audit-log-CURRENTDAY.md file in the log folder of the application. Bear in mind that the bag " +
        "can only hold 100K bytes and will need to have that data removed to store more than that."
      ]

      @config['documentation']['stateless_action'][__method__]['short_description'] = 'Compiles the audit logs for all environments'
    end
  end

  class StatelessAction
    def compile_audit_log out=[]
      compiled_audit_hash = {}

      @config['chef_environments'].each do |env|
        @config['initializer'].initialize_data_bags_for_environment env, false, ['audit']

        @config['initializer'].initialize_audit_bag_contents env

        @config[env]['audit_bag_hash']['audit_log'].each_pair do |day, time_log_hash|
          compiled_audit_hash[day] ||= {}
          time_log_hash.each_pair do |time, log_array|
            compiled_audit_hash[day][time] ||= []
            compiled_audit_hash[day][time] <<  log_array
          end
        end
      end

      compiled_audit_hash.keys.sort.each do |day|
        out << "# Audit Log Entries for #{ Date.parse(day) }"

        entry_count, int_times = 1, []

        compiled_audit_hash[day].keys.sort.each do |time|
          out << "#{ entry_count }. #{ time }"

          log_array_entry_count = 1

          compiled_audit_hash[day][time].each do |log_arr|
            log_arr.each do |log_hash|
              out << @config['auditor'].compile_audit_hash_entry_as_array(log_hash, log_array_entry_count)

              log_array_entry_count += 1
            end
          end if compiled_audit_hash[day].has_key?(time)

          entry_count += 1
        end
      end

      File.open("#{ @config['locs']['chef-log'] }/audit-log-#{ Time.now.strftime("%Y%m%d%H%M%S") }.md", "w") { |f| f.write(out.flatten.join("\n")) }
    end
  end
end
