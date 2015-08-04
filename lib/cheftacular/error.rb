
class Cheftacular
  class Error
    def initialize options, config
      @options, @config  = options, config
    end

    def is_valid_node_name_option? strict_env=false
      raise "Too few arguments, please supply a node name" if @options['node_name'].nil?

      nodes = @config['getter'].get_true_node_objects(true)

      exclusion_args  = [{ if: { not_node: @options["node_name"] } }]
      exclusion_args << { if: { not_env: @options['env'] } } if strict_env

      nodes = @config['parser'].exclude_nodes( nodes, exclusion_args, true )

      raise "Node not found for #{ @options['node_name'] }" if nodes.empty?

      nodes
    end

    def exception_output message, exception='', exit_on_call=true, suppress_error_output=false
      puts "#{ message }\n"

      puts("Error message: #{ exception }\n#{ exception.backtrace.join("\n") }") unless suppress_error_output

      exit if exit_on_call
    end
  end
end
