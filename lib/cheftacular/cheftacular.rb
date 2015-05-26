require 'ridley' #chef tools outside of chef!
require 'highline/import'
require 'optparse'
require 'base64'
require 'openssl'
require 'ffi_yajl'
require 'sshkit'
require 'sshkit/dsl' #yes you have to do it this way
require 'awesome_print'
require 'rest-client'
require 'active_support'
require 'active_support/inflector'
require 'active_support/core_ext'
require 'public_suffix'
require 'yaml'
require 'json'
require 'rbconfig'
require 'fog'
require 'socket'
require 'net/http'
require 'timeout'
require 'slack-notifier'
require 'cloudflare'
require 'zlib'
require 'csv'

Dir["#{File.dirname(__FILE__)}/../**/*.rb"].each { |f| require f }

class Cheftacular
  def initialize options={'env'=>'staging'}, config={}
    @options, @config = options, config

    SSHKit.config.format = :blackhole

    @config['start_time']  = Time.now

    @config['helper']      = Helper.new(@options, @config)

    @config['initializer'] = Initializer.new(@options, @config)

    @config['stateless_action'].initialize_data_bag_contents @options['env'] #ensure basic structure are always maintained before each run

    @config['parser'].parse_application_context if @config['cheftacular']['mode'] == 'application'

    @config['parser'].parse_context

    puts("Preparing to run command \"#{ @options['command'] }\"...") if @options['verbose']

    @config['auditor'].audit_run if @config['cheftacular']['auditing'] == 'true'

    @config['action'].send(@options['command']) if @config['helper'].is_command?(@options['command'])

    @config['stateless_action'].send(@options['command']) if @config['helper'].is_stateless_command?(@options['command'])

    @config['stateless_action'].send('help') if @config['helper'].is_not_command_or_stateless_command?(@options['command'])

    @config['helper'].output_run_stats

    exit #explicitly call this in case some celluoid workers are still hanging around
  end
end
