# Cheftacular

Cheftacular is designed to give you a heroku-like way of interacting with your infrastructure. This gem's purpose is to serve as a 
simple wrapper around several very useful chef and knife tasks. This gem also has two modes, the first mode is devops mode when the gem
detects `mode: 'devops'` in the cheftacular.yml file in the config folder of the github repo it's loaded into. This mode is ideal for devops administrators working
directly in the chef-repo for their organization. The second mode is application mode, this occurs when a cheftacular.yml contains `mode: 'application'` and is ideal for 
applications where non-devops engineers need to be able to deploy or interact with the infrastructure using commands like `cft deploy`.

## No Chef Server?

Read the [initial chef server setup documentation](https://github.com/SocialCentivPublic/cheftacular/blob/master/doc/initial_setup.md)

## Cheftacular Gem Installation Instructions

1. This gem is a little more complex to install than a simple `bundle install`, follow the instructions [here](https://github.com/SocialCentivPublic/cheftacular/blob/master/doc/initial_setup.md#getting-your-repositores-setup)

## Usage

After you have a successful chef and cheftacular installation you can now connect to the chef server and clients via various tools.

Note: You can substitute `cft` for `cftr`, `cheftacular`, or `cftclr`.

1.  To view detailed information about nodes connected to the chef server, run (NOTE: this is a good command to test installation on)

        cft client_list

    You can also pass the -v argument to view more detailed information. This command works in any application the gem is loaded into.

2.  To trigger a chef-client run on all nodes for an application, run

        cft deploy

    After a commit to cause all STAGING nodes to update to the latest commit and restart their services. This command works in any application the gem is loaded into.

    Also worth noting is that you can pass the -p argument to trigger a chef-client run on production instead of staging. 

4.  To run migrations for a specific application, run

        cft migrate

    Like with `cft deploy`, you simply just need to pass -p to hit production servers instead.

5.  To tail a log for a specific NODE_NAME, run

        cft log -n NODE_NAME

    This will output any changes to a node's staging.log (or production.log) to your terminal

7.  To open a console session on a (rails) node, run

        cft console

8.  To add a new web server (and worker server as well in the case of an api), run

        cft scale up

## Additional Reading (Features and Commands)

For more information about these commands and the several commands only available if you are running them from the chef-repo directly, please see the [Cheftacular Scripts Readme](https://github.com/SocialCentivPublic/cheftacular/blob/master/lib/cheftacular/README.md)
