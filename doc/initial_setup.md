# Getting started on Cheftacular (06/20/2015)

This is a guide from the ground up, setting up a Chef 12 server on digital ocean, connecting to it via cheftacular, and starting to setup your own infrastructure.

## Chef Server on Digital Ocean

1. Visit https://cloud.digitalocean.com and go through the signup process

2. You will need to provide credit card information and so on to create droplets.

3. Create a droplet (2 GB is ideal unless you'll be managing 50+ nodes) and name it after your chef-server name.

    1. NOT! While not explicitly necessary, it is a *VERY GOOD IDEA* to enable public key authenication here. See [this guide](https://www.digitalocean.com/community/tutorials/how-to-use-ssh-keys-with-digitalocean-droplets).

4. While the droplet is creating, visit their API tab and create an API key. Write down this key as you'll be needing it soon.

5. This is a good time to start setting up DNS details for the new environment. 

    1. Setup the domain you would like to use for the environment using your domain registrar of choice.

    2. Set the name servers to ns1.digitalocean.com, ns2.digitalocean.com, ns3.digitalocean.com

    3. In the DNS tab of the digitalocean site, enter the TLD of the new domain (you must attach it to the new server but this be removed)

    4. Setup the subdomain for the chef server

6. The Chef Server

    1. Login to your chef server and use this curl command: `curl -L https://web-dl.packagecloud.io/chef/stable/packages/ubuntu/trusty/chef-server-core_12.1.0-1_amd64.deb > /tmp/chef-server-core_12.1.0-1_amd64.deb`

        1. NOTE! You may want to lookup the latest version numbers!

        2. This would also be the step you setup any additional layers of security (a deploy user) and so on, bear in mind that chef itself will always run as root and as the chef server will never interact with itself via your own deploys, it's fine to leave it with only root setup as long as you setup public key authentication

    2. At this point you can safely follow the guide at http://docs.chef.io/server/install_server.html#standalone

        1. NOTE! Make sure to copy your organization-chef-validator key and your admin key to your local workstation!

        2. Another good guide can be found at https://www.digitalocean.com/community/tutorials/how-to-set-up-a-chef-12-configuration-management-system-on-ubuntu-14-04-servers

    3. If you have a SSL cert, follow the steps at http://docs.chef.io/server/server_security.html

        1. It also helps to check out http://www.bitlancer.com/2014/10/custom-chef-server-url/

## Getting Your Workstation Setup

1. Follow the steps at http://docs.chef.io/client/install_workstation.html

2. Run `knife ssl check` to ensure everything works right for connecting to the chef server.

3. Generate a data bag key with `openssl rand -base64 512 | tr -d '\r\n' > ~/.chef/data_bag_key`

4. For Chef 12, Remember to edit your knife.rb file with `chef_server_url:"https://server_domain_or_IP/organizations/org_name"`, this is very important and easily overlooked.

5. Your .chef folder should look similar to the folder found [here](https://github.com/SocialCentivPublic/cheftacular/blob/master/examples/.chef)

## Getting Your Repositories Setup

1. Your chef-repo needs to have a Gemfile and cheftacular, if you don't have a gemfile, you can use the template [here](https://github.com/SocialCentivPublic/cheftacular/blob/master/examples/Gemfile)

2. Run `bundle install` to install Cheftacular and its dependencies

3. Run `cft initialize_cheftacular_yml`, this will create your config/cheftacular.yml

    1. NOTE! You must edit this file to reflect your desired environment! Anything not explained by the comments in the file accurately should be raised as an issue!

4. Run `cft initialize_data_bag_contents`. This command will create many data bags on the chef server and fill them with initial data.

    1. NOTE! This command will say what to run to fix various warnings about data bags that require user input. Please read the output.

    2. Continue running this command and doing what it says *UNTIL* it stops returning issues with your overall configuration.

5. If you're doing git based deploys...

    1. Create a github user on github to be your deploy user (it should not be yourself!)

    2. After creating the github user, create a ssh key for it using https://help.github.com/articles/generating-ssh-keys/

        1. Settings -> SSH keys

    3. Associate the ssh key with the account and place the public and private key generated in your .chef folder

    4. Create a OAuth token for the account in the Settings -> Personal access tokens page

    5. Add the SSH key you created for this new user to your .chef folder

    6. Run `cft create_git_key NAME_OF_DEPLOY_SSH_KEY_FILE OAUTH_TOKEN`