module SSHKit
  module Backend
    class Netssh
      def set_log_loc_and_timestamp locs
        [locs['chef-log'], Time.now.strftime("%Y%m%d%H%M%S")]
      end

      def sudo_capture pass, *args
        capture :echo, pass, :|, :sudo, '-S', *args
      end
    end
  end
end
