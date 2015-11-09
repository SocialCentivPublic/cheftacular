require 'ridley'
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
require 'csv'

Dir["#{File.dirname(__FILE__)}/../**/*.rb"].each { |f| require f }

class Cheftacular
  def initialize options={'env'=>'staging'}, config={}
    @options, @config                = options, config
    SSHKit.config.format             = :blackhole
    #Fog::Logger[:warning]            = nil
    @config['start_time']            = Time.now
    @config['helper']                = Helper.new(@options, @config)
    @config['initialization_action'] = InitializationAction.new(@options, @config)
    @config['filesystem']            = Cheftacular::FileSystem.new(@options, @config)
    @config['initializer']           = Initializer.new(@options, @config)

    if @config['helper'].is_initialization_command?(ARGV[0])
      @options['command'] = ARGV[0] #this is normally set by parse_context but that is not run for initialization commands
    else
      @config['stateless_action'].initialize_data_bag_contents(@options['env']) #ensure basic structure are always maintained before each run

      @config['parser'].parse_application_context if @config['helper'].running_in_mode?('application')

      @config['parser'].parse_context

      puts("Preparing to run command \"#{ @options['command'] }\"...") if @options['verbose']

      @config['auditor'].audit_run if @config['cheftacular']['auditing']

      @config['queue_master'].work_off_slack_queue #this occurs twice so commands that don't "end" can be queued
    end

    @config['stateless_action'].check_cheftacular_yml_keys unless @config['helper'].is_initialization_command?(ARGV[0])

    @config['action'].send(@options['command']) if @config['helper'].is_command?(@options['command'])

    @config['stateless_action'].send(@options['command']) if @config['helper'].is_stateless_command?(@options['command'])

    @config['stateless_action'].send('help') if @config['helper'].is_not_command_or_stateless_command?(@options['command'])

    @config['queue_master'].work_off_slack_queue unless @config['helper'].is_initialization_command?(@options['command'])

    @config['helper'].output_run_stats

    exit #explicitly call this in case some celluoid workers are still hanging around
  end
end
