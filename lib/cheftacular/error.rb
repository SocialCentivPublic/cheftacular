
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
  end
end
