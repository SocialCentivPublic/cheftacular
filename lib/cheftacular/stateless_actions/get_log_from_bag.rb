
class Cheftacular
  class StatelessActionDocumentation
    def get_log_from_bag
      @config['documentation']['stateless_action'][__method__] ||= {}
      @config['documentation']['stateless_action'][__method__]['long_description'] = [
        "`cft get_log_from_bag <NODE_NAME-COMMAND_TYPE>` this command grabs the latest command run log from the data bags " +
        "and saves it to your log directory. There are different types of logs saved per server depending on command."
      ]

      @config['documentation']['stateless_action'][__method__]['short_description'] = 'Fetches all the logs stored in the current environment bags'

      @config['documentation']['application'][__method__] = @config['documentation']['stateless_action'][__method__]
    end
  end

  class StatelessAction
    def get_log_from_bag
      #TODO https://stackoverflow.com/questions/17882463/compressing-large-string-in-ruby
      log_loc, timestamp = @config['helper'].set_log_loc_and_timestamp

      @options['role'] = 'all' unless @options['role']

      nodes = @config['getter'].get_true_node_objects(true)

      nodes = @config['parser'].exclude_nodes( nodes, [{ unless: { env: @options['env'] }}])

      nodes.each do |node|
        if @config[@options['env']]['logs_bag_hash'].has_key?("#{ node.name }-run")
          puts("Found log data in logs bag. Outputting to #{ log_loc }/stashedlog/#{ node.name }-deploystash-#{ @config[@options['env']]['logs_bag_hash']["#{ node.name }-run"][:timestamp] }.txt") unless @options['quiet']

          File.open("#{ log_loc }/stashedlog/#{ node.name }-deploystash-#{@config[@options['env']]['logs_bag_hash']["#{ node.name }-run"][:timestamp] }.txt", "w") do |f|
            f.write(@config[@options['env']]['logs_bag_hash']["#{ node.name }-run"][:text])
          end

          puts(@config[@options['env']]['logs_bag_hash']["#{ node.name }-run"][:text]) if @options['verbose']
        end
      end
    end
  end
end
