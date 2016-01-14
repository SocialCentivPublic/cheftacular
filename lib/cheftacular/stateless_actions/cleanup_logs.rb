
class Cheftacular
  class StatelessActionDocumentation
    def cleanup_logs
      @config['documentation']['stateless_action'][__method__] ||= {}
      @config['documentation']['stateless_action'][__method__]['long_description'] = [
        "`cft cleanup_logs [DIRECTORIES_TO_NOT_DELETE]` this command allows you to clear your local log files",

        [
          "    1. By default, this command will delete all the cheftacular directories in your log folder.",

          "    2. This command supports a comma separated list of folders you don't want to delete."
        ]
      ]

      @config['documentation']['stateless_action'][__method__]['short_description'] = 'Clears cheftacular log directories'

      @config['documentation']['application'][__method__] = @config['documentation']['stateless_action'][__method__]
    end
  end

  class InitializationAction
    def cleanup_logs
      
    end
  end

  class StatelessAction
    def cleanup_logs directories_to_not_delete=''
      directories_to_not_delete   = ARGV[1] if directories_to_not_delete.blank?
      directories_to_not_delete ||= ''
      
      @config['filesystem'].remove_log_directories(directories_to_not_delete.split(','))

      @config['filesystem'].initialize_log_directories(false)
    end
  end
end
