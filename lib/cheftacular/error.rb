
class Cheftacular
  class Error
    def initialize options, config
      @options, @config  = options, config
    end

    def is_valid_node_name_option?
      raise "Too few arguments, please supply a node name" if @options['node_name'].nil?

      nodes = @config['getter'].get_true_node_objects(true)

      nodes = @config['parser'].exclude_nodes( nodes, [{ if: { not_node: @options["node_name"] } }], true )

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
