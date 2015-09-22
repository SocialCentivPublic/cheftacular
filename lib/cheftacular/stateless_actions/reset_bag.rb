
class Cheftacular
  class StatelessActionDocumentation
    def reset_bag
      @config['documentation']['stateless_action'] <<  [
        "`cft reset_bag BAG_NAME` this command allows you to reset a data bag item to an empty state. " +
        "Run this on full data bags to clear them out. "
      ]
    end
  end

  class StatelessAction
    def reset_bag bag_name='', bag_env=''
      raise "This action can only be performed if the mode is set to devops" unless @config['helper'].running_in_mode?('devops')

      bag_name = ARGV[1]         if bag_name.blank?
      bag_env  = @options['env'] if bag_env.blank?

      begin
        @config['ChefDataBag'].send("reset_#{ bag_name }_bag")

        puts "Successfully reset bag #{ bag_name }."
      rescue NoMethodError => e
        puts "You are not able to reset the bag \"#{ bag_name }\" via reset_bag, please use knife to edit the contents.\n #{ e }"
      end

      @config['stateless_action'].clear_caches
    end
  end
end
