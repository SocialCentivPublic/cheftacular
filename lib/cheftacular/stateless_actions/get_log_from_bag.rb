
class Cheftacular
  class StatelessActionDocumentation
    def get_log_from_bag
      @config['documentation']['stateless_action'] <<  [
        "`cft get_log_from_bag <NODE_NAME-COMMAND_TYPE>` this command grabs the latest command run log from the data bags " +
        "and saves it to your log directory. There are different types of logs saved per server depending on command."
      ]

      @config['documentation']['application'] << @config['documentation']['stateless_action'].last
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
        if @config[@options['env']]['logs_bag_hash'].has_key?("#{ node.name }-deploy")
          puts("Found log data in logs bag. Outputting to #{ log_loc }/#{ node.name }-deploystash-#{ @config[@options['env']]['logs_bag_hash']["#{ node.name }-deploy"][:timestamp] }.txt") unless @options['quiet']

          File.open("#{ log_loc }/#{ node.name }-deploystash-#{@config[@options['env']]['logs_bag_hash']["#{ node.name }-deploy"][:timestamp] }.txt", "w") do |f|
            f.write(@config[@options['env']]['logs_bag_hash']["#{ node.name }-deploy"][:text])
          end

          puts(@config[@options['env']]['logs_bag_hash']["#{ node.name }-deploy"][:text]) if @options['verbose']
        end
      end
    end
  end
end
