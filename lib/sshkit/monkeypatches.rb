module SSHKit
  class Command
    #returns the full contents of stdout when an error occurs rather than just the first line (needed for chef debugging)
    def exit_status=(new_exit_status)
      @finished_at = Time.now
      @exit_status = new_exit_status

      if options[:raise_on_non_zero_exit] && exit_status > 0
        message = ""
        message += "#{command} exit status: " + exit_status.to_s + "\n"
        message += "#{command} stdout: " + (full_stdout.strip || "Nothing written") + "\n"
        message += "#{command} stderr: " + (full_stderr.strip || 'Nothing written') + "\n\n"
        raise Failed, message
      end
    end
  end

  module Runner
    class Parallel < Abstract
      def execute
        threads = []
        hosts.each do |host|
          threads << Thread.new(host) do |h|
            begin
              backend(h, &block).run
            rescue Exception => e
              e2 = ExecuteError.new e
              raise e2, "Exception while executing #{host.user ? "as #{host.user}@" : "on host "}#{host}:\n#{e.message}\n#{ e.backtrace.join("\n") }"
            end
          end
        end
        threads.map(&:join)
      end
    end
  end
end
