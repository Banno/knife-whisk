knife-whisk
===========

[knife-whisk](https://github.com/Banno/knife-whisk) is a utility for quickly
whipping up servers. A best practice is for a team to collect and keep the
commands used for creating and bootstrapping nodes in source control, this tool
does just that. It also goes a step further and lets you ask for a machine with
just a few parameters and hands you a `knife ec2 server create` command with all
of the default configuration. This is important so the operators can maintain
the defaults for using ec2, but they can be overridden as needed. We've also
supplied a `knife whisk history` command that will show you all the `knife ec2
server create` commands that have been run by the team, as long as they use
knife-santoku and it's properly configured. All together, this will give us
a "frictionless" tool for understanding how servers are created in our
organization and quick access to recreate them during a crisis.
