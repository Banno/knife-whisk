# knife-whisk

A utility for quickly whipping up new servers in a team environment

![whisk](https://github.com/Banno/knife-whisk/raw/master/whisk.jpg)
## Overview
Chef is a great tool for configuring servers once they're up, but it doesn't address configuration management for initializing cloud servers in the first place. This tool lets your team define named servers and configuration mixins to help your team always create new servers uniformly. Currently, it will generate `knife ec2 server create` commands based upon the configuration defined in your `whisk.yml` file. You're free to provide overrides and additional flags when generating a new command to spit out a slight alteration of an existing server's config.

All together, this tool provides us with a "frictionless" experience for understanding how servers are created in our organization and quick access to recreate them correctly during a crisis.

## Usage
Assume you've got knife-whisk installed and configured correctly and it's pointing to a whisk.yml that looks like this:

```
mixins:
  defaults:
  	provider: aws
    image: ami-950680fc      # ubuntu instance store
    subnet: subnet-12345678  # private subnet
    region: us-east-1
    user-data: user_data/before_bootstrap.sh
    flavor: m1.small
    ssh-user: ubuntu
    template: chef_full
    security-groups: default
  ebs_instance:
    image: ami-e50e888c
  public_subnet:
    subnet: subnet-87654321

provider_config:
  aws:
    cli_command: "ec2 sever create"
   		security-groups:
        default: sg-12345678
        java_app_server: sg-34567890
  kvm:
    cli_command: "vm create"
    
servers:
  app_server:
    mixins:
    - defaults
    config:
      provider: aws
      run-list:
      - "recipe[application-wrapper]"
      security-groups:
      - default
      - java_app_server
      environment: prod
```

`knife whisk generate` will work like this:

```
$ knife whisk generate app_server
knife ec2 server create --image ami-950680fc --subnet subnet-12345678 --region us-east-1 --user-data user_data/before_bootstrap.sh --flavor m1.small --ssh-user ubuntu --template chef_full --run-list recipe[application-wrapper] --environment prod --security-groups-ids sg-12345678,sg-3456789
```

Let's mix in the public_subnet mixin:

```
$ knife whisk generate app_server --mixins public_subnet

knife ec2 server create --image ami-950680fc --subnet subnet-87654321 --region us-east-1 --user-data user_data/before_bootstrap.sh --flavor m1.small --ssh-user ubuntu --template chef_full --run-list recipe[application-wrapper] --environment prod --security-groups-ids sg-12345678,sg-34567890
```

See how the subnet flag was updated? Now let's try something with overrides.

```
 $ knife whisk generate app_server --mixins public_subnet --overrides "--environment dev --flavor m2.4xlarge"
 
knife ec2 server create --image ami-950680fc --subnet subnet-87654321 --region us-east-1 --user-data user_data/before_bootstrap.sh --flavor m2.4xlarge --ssh-user ubuntu --template chef_full --run-list recipe[application-wrapper] --environment dev --security-groups-ids sg-12345678,sg-34567890
```

This is where knife-whisk shines. You don't have to be aware of all the ins and outs of AWS or whatever cloud provider you use, you just ask for the defaults or whatever other mixins you need on the server you want to fire up.

Most importantly, as a team you define what your production servers look like in your whisk.yml file and you'll never bring up a new node with a missing security group because you forgot some ancillary service was on the node that needed it.

Security groups with VPC are a pain so we added a way to call them by name in your whisk.yml. knife-whisk will translate the `--security-groups name1,name2` to `--security-groups-ids id1,id2` according to what is in your "security-groups" lookup section.

## Installation

Add this line to your application's Gemfile:

```
gem 'knife-whisk'
```

And then execute:

```
$ bundle install
```

Or install it yourself as:

```
$ gem install knife-whisk
```

##Configuration

A `whisk.yml` file must exist for knife-whisk to work. There is an example in the example directory. The path to the file can be set in your knife config, via the `--whisk-config` or `-C` flag, or will look for it by default in your .chef directory.

Best way to do it is to just put your whisk.yml in your chef directory under config/ and put something like this in your knife.rb.

```
knife[:whisk_config_file] = "#{ENV['CHEF_REPO_DIR']}/config/whisk.yml"
```

##Subcommands

This plugin provides the following Knife subcommands. Specific command options can be found by invoking the subcommand with a `--help` flag.

### knife whisk mixin list
Lists the available mixins
###knife whisk mixin show
Shows the yaml output of the details of the mixin
###knife whisk server list
Lists the available servers templates
###knife whisk server show
Shows the yaml output of the details of the server
###knife whisk generate
Outputs a knife command with the provided server template, mixins, or overrides. When using the `--overrides` flag you must provide long form flag names, I.E `--node-name` not `-N`.

####Examples:

```
knife whisk generate --mixins defaults,public_subnet --overrides "--node-name server1 --image ami-123456"
```

```
knife whisk generate application_server
```

```
knife whisk generate application_server --mixins public_subnet
```

```
knife whisk generate application_server --overrides "--environment dev --node-name dev-application-server"
```

## Tab Completion

### ZSH
This repository also includes a zsh folder, with a replacement for oh-my-zsh's knife plugin.  Copy that to your ~/.oh-my-zsh/plugins/knife folder, and enabled the plugin by adding "knife" to your plugins=() in your .zshrc. You will likely need to reload your shell. 

## Todo
* supprot for --json-attributes knife flag
* whisk add mixin
* whisk add server
* whisk provider list
* bash tab completion

##Authors
- Nic Grayson (<nic.grayson@banno.com>)
- Kevin Nuckolls (<kevin.nuckolls@banno.com>)
- Danny Lockard (<danny.lockard@banno.com>)

If you want to contribute, thanks! Please see [contribution guidelines](https://github.com/Banno/knife-whisk/blob/master/CONTRIBUTING.markdown).
