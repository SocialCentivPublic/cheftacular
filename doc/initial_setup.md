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

        1. NOTE! Make sure to copy your admin key to your local workstation!

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

4. Users setting up chef for the first time should continue on, those just installing this gem for an application within an organization that already has a chef-repo can return to the original README.

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

6. Setting up the chef-repo

    1. At this point you should be to run `cft knife_upload` (which is a simple wrapper around the knife equivalent). This will simply create your cookbooks and recipes on the chef server

        1. NOTE! The purposes of this guide is not to make you into a Chef expert but to set you up with Cheftacular, you'll still need to create (and test) your chef cookbooks and recipes if you're starting from scratch (this is also the step where actual DevOps Engineers generally come in).

        2. There is a special command called `cft clean_cookbooks [force]` this command will examine the dependencies of your wrapper cookbook(s) (set in your cheftacular.yml) and utilize berkshelf to automatically download them and place them into your working chef repo.

    2. Next you'll need to create the nodes_dir directory in the root of your chef_repo. References to how this directory should look can be found [here](https://github.com/SocialCentivPublic/cheftacular/blob/master/examples/nodes_dir)

        1. You will need to create a json template file or a json exact match file for each node you want to match to a set of roles

        2. For example, mynode.json would match nodes named mynode01, mynode02, mynode03, etc (along with a node named mynode) but *NOT* mynode01p.json

        3. As another example a file named dbmaster.json could be used to directly refer to a node called dbmaster

        4. It is important that the directory and the chef_environment of the node match

        5. *It is extremely important that none of the files (template or exact match) never match the same node multiple times*

    3. With the nodes directory in place, you now need to populate the roles you referred to in the node directory, an example of a role file can be found [here](https://github.com/SocialCentivPublic/cheftacular/blob/master/examples/db.rb)

        1. After populating your roles, you can run `cft upload_roles` (or the knife equivalent) to upload the roles to the chef server

    4. Run `knife environment create staging` and `knife environment create production` along with any other environments you would like to have.

    5. Run `cft upload_nodes` to get your node role data in place (You don't need to have nodes active to run this command). It will prompt you if you want to overwrite nil hashes with your node data, just enter "y" or "yes" for each.

## Setting up your first node

    1. Run `cft help cloud_bootstrap` and `cft help cloud` and have a look over the help dialogs.

    2. Double check your cheftacular.yml to make sure that your *preferred_cloud* key is set to your desired cloud. You will also need to make sure you have VALID api credentials entered into the *cloud_authentication* hash.

    2. Run `cft cloud flavors list`, this will return a list of all *valid* flavor names, find your desired default flavor and enter it's **name** attribute into your cheftacular.yml's *default_flavor_name* key. Also take note of the flavor **name** you would like to use for whatever your first node will be.

        1. A flavor is a "type" of server, for some providers, it is usually a combination of the server's hard drive space and RAM resources though other factors like network IO and bandwidth can be determined here as well.

    3. Run `cft cloud images list`, Image names vary between providers so be sure to find the exact name of the image you want to use as your default. Enter this **name** attribute into your cheftacular.yml

        1. Based off what you chose for your name attribute, enter `centos|coreos|debian|fedora|redhat|ubuntu|vyatta` for your *preferred_cloud_os* in your cheftacular.yml. **NOTE! Only Ubuntu is currently fully supported for bootstrapping**.

        1. An image is a way to describe an operating system of a server, it can be based off a default (like various linux distributions like Debian, Ubuntu, CentOS, etc) or it can be based off of a user-generated image. Most cloud providers allow users to generate their own images based off a server the cloud provider is hosting.

    4. Run `cft cloud regions list` and find the region you would like to create servers in, add this **name** value to your cheftacular.yml under *preferred_cloud_region*

        1. Rackspace does not currently support API calls for regions, you can find the list of regions [here](http://www.rackspace.com/knowledge_center/article/about-regions)

    5. Run `cft cloud_bootstrap YOUR_NODE_NAME YOUR_FLAVOR_NAME`

        1. This will (if everything works correctly) create a node and attach it to your staging environment. It will also use the role and node definitions you set to attempt to match role data to the server automatically. If the process fails, please raise an issue on Github.

    6. With a node in place, you can deploy to it to begin testing your cookbooks and recipes with `cft deploy -r ROLE_NAME_THE_NODE_HAS`

        1. For the full list of flags for `cft deploy` please check `cft arguments` and `cft help deploy`