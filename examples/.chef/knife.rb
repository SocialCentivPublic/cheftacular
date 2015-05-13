user =                   `whoami`.chop
current_dir =            File.dirname(__FILE__)
log_level                :info
log_location             STDOUT
node_name                'YOUR DEFAULT DEPLOY CHEF USER HERE'
client_key               "#{current_dir}/#{ node_name }.pem"
validation_client_name   'chef-validator'
validation_key           "#{current_dir}/chef-validator.pem"
chef_server_url          'https://chef.example.com'
syntax_check_cache_path  "#{current_dir}/syntax_check_cache"
knife[:editor] =         '/usr/bin/nano'
