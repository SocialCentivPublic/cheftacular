module SSHKit
  module Backend
    class Netssh
      def start_commit_check name, ip_address, options, locs, cheftacular, out={'name'=>'', 'time'=> ''}
        app_loc = "#{ cheftacular['base_file_path'] }/#{ options['repository'] }/releases"
        
        if test("[ -d #{ app_loc } ]") #true if file exists
          within app_loc do
            out['name'] = capture( :ls, '-rt', :|, :tail, '-1' )

            out['time'] = Time.parse(capture( :stat, out['name'], '--printf=%y' )).strftime('%Y-%m-%d %I:%M:%S %p')
          end
        end

        out
      end
    end
  end
end
