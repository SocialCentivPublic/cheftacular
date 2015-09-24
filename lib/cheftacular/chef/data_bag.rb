
class Cheftacular
  class ChefDataBag
    def initialize options={}, config={}
      @options, @config = options, config
    end

    #this will only intialize bags (and their hashes) if they don't exist. Use ridley data bag methods to reload the data etc
    def init_bag bag_env, bag_name, encrypted=true
      @config['ridley'].data_bag.create(name: bag_env) if @config['ridley'].data_bag.find(bag_env).nil?

      if @config['ridley'].data_bag.find(bag_env).item.find(bag_name).nil?
        @config['ridley'].data_bag.find(bag_env).item.create(id: bag_name)
      end

      @config[bag_env] ||= {}

      if !@config[bag_env].has_key?("#{ bag_name }_bag") || !@config[bag_env].has_key?("#{ bag_name }_bag_hash")
        @config[bag_env]["#{ bag_name }_bag"] = @config['ridley'].data_bag.find(bag_env).item.find(bag_name)

        self.instance_eval "@config['#{ bag_env }']['#{ bag_name }_bag_hash'] = @config['#{ bag_env }']['#{ bag_name }_bag']#{ encrypted ? '.decrypt' : '' }.to_hash"
      end
    end

    def save_logs_bag bag_env="options"
      return true if @config['helper'].running_on_chef_node?
      
      env = bag_env == 'options' ? @options['env'] : bag_env

      item = @config[env]['logs_bag'].reload

      item.attributes = item.attributes.deep_merge(@config[env]['logs_bag_hash'].dup)

      begin
        item.save
      rescue Ridley::Errors::HTTPRequestEntityTooLarge => e
        puts "WARNING! #{ e }! The logs from this run will not be saved on the chef server. Wiping the bag so future runs can be saved."

        item.attributes = @config[env]['logs_bag_hash'].keep_if {|key,val| key == 'id'}

        sleep 5

        item.save

        @config[env]['logs_bag_hash'] = @config[env]['logs_bag'].reload.to_hash
      end
    end

    def save_audit_bag bag_env="options"
      env = bag_env == 'options' ? @options['env'] : bag_env

      save_bag 'audit', bag_env, @config[env]['audit_bag'], @config[env]['audit_bag_hash']
    end

    def save_authentication_bag bag_env="default"
      save_bag 'authentication', bag_env, @config['default']['authentication_bag'], @config['default']['authentication_bag_hash'], true
    end

    def save_cheftacular_bag bag_env="default"
      save_bag 'cheftacular', bag_env, @config['default']['cheftacular_bag'], @config['default']['cheftacular_bag_hash']
    end

    def save_environment_config_bag bag_env='default'
      save_bag 'environment_config', bag_env, @config['default']['environment_config_bag'], @config['default']['environment_config_bag_hash']
    end

    def save_chef_passwords_bag bag_env="options"
      env = bag_env == 'options' ? @options['env'] : bag_env

      save_bag 'chef_passwords', bag_env, @config[env]['chef_passwords_bag'], @config[env]['chef_passwords_bag_hash'], true
    end

    def save_server_passwords_bag bag_env="options"
      env = bag_env == 'options' ? @options['env'] : bag_env

      save_bag 'server_passwords', bag_env, @config[env]['server_passwords_bag'], @config[env]['server_passwords_bag_hash'], true
    end

    def save_addresses_bag bag_env="options"
      env = bag_env == 'options' ? @options['env'] : bag_env

      save_bag 'addresses', bag_env, @config[env]['addresses_bag'], @config[env]['addresses_bag_hash']
    end

    def save_config_bag bag_env="options"
      env = bag_env == 'options' ? @options['env'] : bag_env

      save_bag 'config', bag_env, @config[env]['config_bag'], @config[env]['config_bag_hash']
    end

    def save_node_roles_bag bag_env="options"
      env = bag_env == 'options' ? @options['env'] : bag_env

      save_bag 'node_roles', bag_env, @config[env]['node_roles_bag'], @config[env]['node_roles_bag_hash']
    end

    def reset_addresses_bag bag_env="options"
      env = bag_env == 'options' ? @options['env'] : bag_env

      reset_bag 'addresses', env
    end

    def reset_audit_bag bag_env='options'
      env = bag_env == 'options' ? @options['env'] : bag_env

      reset_bag 'audit', env
    end

    def reset_cheftacular_bag bag_env="default"
      reset_bag 'cheftacular', bag_env
    end

    def reset_environment_config_bag bag_env='default'
      reset_bag 'environment_config', bag_env
    end

    def reset_node_roles_bag bag_env="options"
      env = bag_env == 'options' ? @options['env'] : bag_env

      reset_bag 'node_roles', env
    end

    private
    def reset_bag bag_name, bag_env, encrypted=false
      raise "Cannot reset bag #{ bag_name } in #{ bag_env } as it does not exist!" if @config['ridley'].data_bag.find(bag_env).item.find(bag_name).nil?

      @config['ridley'].data_bag.find(bag_env).item.delete(bag_name)

      init_bag bag_env, bag_name, encrypted
    end

    def save_bag bag_name, bag_env, bag, bag_hash, encrypted=false
      return true if @config['helper'].running_on_chef_node?

      new_bag_hash = bag_hash.deep_dup
      item         = bag.reload

      load_hash = encrypted ? item.decrypt.to_hash.deep_merge(new_bag_hash) : item.attributes.deep_merge(new_bag_hash)

      item.attributes = encrypted ? @config['encryptor'].return_encrypted_hash(load_hash) : load_hash

      item.save
    rescue Ridley::Errors::HTTPRequestEntityTooLarge => e
      msg = "FATAL! Bag #{ bag_name } in environment bag #{ bag_env } was not able to be saved because it has grown too large! This bag must cleaned up ASAP!"
      
      @config['error'].exception_output msg, e
    end
  end
end
