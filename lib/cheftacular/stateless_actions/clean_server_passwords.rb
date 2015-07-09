
class Cheftacular
  class StatelessActionDocumentation
    def clean_server_passwords
      
    end
  end

  class StatelessAction
    def clean_server_passwords
      #TODO clean up non-existent entries in all envs server_password bags
      raise "This method is not yet implemented"
      raise "This action can only be performed if the mode is set to devops" unless @config['helper'].running_in_mode?('devops')
    end
  end
end
