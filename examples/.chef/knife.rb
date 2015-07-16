user =                   `whoami`.chop
current_dir =            File.dirname(__FILE__)
log_level                :info
log_location             STDOUT
node_name                'YOUR DEFAULT DEPLOY CHEF USER HERE'
client_key               "#{current_dir}/#{ node_name }.pem"
#validation_client_name   'chef-validator' #you don't need this key for chef 12, it will break your bootstraps
#validation_key           "#{current_dir}/chef-validator.pem" #you don't need this key for chef 12, it will break your bootstraps
chef_server_url          'https://chef.example.com/organizations/my-organization'
syntax_check_cache_path  "#{current_dir}/syntax_check_cache"
knife[:editor] =         '/usr/bin/nano'
