
class Cheftacular
  class StatelessActionDocumentation
    def replication_status
      @config['documentation']['stateless_action'][__method__] ||= {}
      @config['documentation']['stateless_action'][__method__]['long_description'] = [
        "`cft replication_status` will check the status of the database master and slaves in every environment. " +
        "Also lists how far behind the slaves are from the master in milliseconds."
      ]

      @config['documentation']['stateless_action'][__method__]['short_description'] = 'Checks the replication status for the current environment (postgres only)'
    end
  end

  class StatelessAction
    def replication_status rep_status_hash={}, out=[] 
      
      nodes = @config['getter'].get_true_node_objects(true)

      primary_nodes = @config['parser'].exclude_nodes( nodes, [{ if: { env: '_default' }}, { unless: "role[db_primary]"}] )

      slave_nodes = @config['parser'].exclude_nodes( nodes, [{ if: { env: '_default' }}, { unless: "role[db_slave]"}] )

      (primary_nodes + slave_nodes).map {|n| n.chef_environment}.uniq.each do |env|
        @config['initializer'].initialize_data_bags_for_environment env, false, ['server_passwords']

        @config['initializer'].initialize_passwords env
      end

      #this must always precede on () calls so they have the instance variables they need
      options, locs, ridley, logs_bag_hash, pass_bag_hash, bundle_command, cheftacular, passwords = @config['helper'].set_local_instance_vars

      on ( primary_nodes.map { |n| @config['cheftacular']['deploy_user'] + "@" + n.public_ipaddress } ) do |host|
        n = get_node_from_address(nodes, host.hostname)

        puts "Beginning replication status report run for #{ n.name } (#{ n.public_ipaddress })"

        env = n.name.split('_').first

        rep_status_hash[n.name] = start_replication_report( n.name, n.public_ipaddress,  options, locs, passwords)
      end

      on ( slave_nodes.map { |n| @config['cheftacular']['deploy_user'] + "@" + n.public_ipaddress } ) do |host|
        n = get_node_from_address(nodes, host.hostname)

        puts "Beginning slave replication status report run for #{ n.name } (#{ n.public_ipaddress })"

        env = n.name.split('_').first

        rep_status_hash[n.name] = start_slave_replication_report( n.name, n.public_ipaddress,  options, locs, passwords)
      end

      rep_status_hash.each_pair do |serv_name, output|
        out << "#{ serv_name }:"

        output.join("\n").split("\n").each do |line|
          out << "  #{ line }\n"
        end

        out << "\n"
      end

      puts(out)
    end
  end
end

module SSHKit
  module Backend
    class Netssh

      def start_replication_report name, ip_address, options, locs, passwords, out=[]

        psql_commands = [
          "select client_addr, state, sent_location, write_location, flush_location, replay_location, sync_priority from pg_stat_replication;",
          %{
            SELECT
                client_addr,
                sent_offset - (
                    replay_offset - (sent_xlog - replay_xlog) * 255 * 16 ^ 6 ) AS byte_lag
            FROM (
                SELECT
                    client_addr,
                    ('x' || lpad(split_part(sent_location,   '/', 1), 8, '0'))::bit(32)::bigint AS sent_xlog,
                    ('x' || lpad(split_part(replay_location, '/', 1), 8, '0'))::bit(32)::bigint AS replay_xlog,
                    ('x' || lpad(split_part(sent_location,   '/', 2), 8, '0'))::bit(32)::bigint AS sent_offset,
                    ('x' || lpad(split_part(replay_location, '/', 2), 8, '0'))::bit(32)::bigint AS replay_offset
                FROM pg_stat_replication
            ) AS s;
          } #http://www.dansketcher.com/2013/01/27/monitoring-postgresql-streaming-replication/
        ]

        psql_commands.each do |cmnd|
          out << sudo_capture( passwords[ip_address], :sudo, "su", "-", "postgres", "-c \"psql -c \\\"#{ cmnd }\\\"\"" )
        end

        out
      end

      def start_slave_replication_report name, ip_address, options, locs, passwords, out=[]

        psql_commands = [
          "select now() - pg_last_xact_replay_timestamp() AS replication_delay;",
        ]

        begin
          psql_commands.each do |cmnd|
            out << sudo_capture( passwords[ip_address], :sudo, "su", "-", "postgres", "-c \"psql -c \\\"#{ cmnd }\\\"\"" )
          end
        rescue StandardError => e
          out << "This slave database is still setting up its replication! The current status of its process is:"
          out << capture( :ps, :aux, :|, :grep, :startup, :|, :grep, '-v', :grep)
          out << "The reason for the failure was: #{ e }"
        end

        out
      end
    end
  end
end
