module SSHKit
  module Backend
    class Netssh
      def set_log_loc_and_timestamp locs
        [locs['chef-log'], Time.now.strftime("%Y%m%d%H%M%S")]
      end

      def sudo_capture pass, *args
        capture :echo, pass, :|, :sudo, '-S', *args
      end

      def has_run_list_in_role_map? run_list, role_map_hash
        role_map_hash.each_value do |map_hash|
          return true if run_list.include?("role[#{ map_hash['role_name'] }]")
        end

        false
      end
    end
  end
end
