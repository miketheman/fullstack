fullstack
=========
Full-stack DevOps demo

The purpose of this is to demonstrate some great automation tools in orchestra.

Things used
-----------
(in alphabetic order)

* [Apache2](http://httpd.apache.org/) (with [mod_wsgi](http://code.google.com/p/modwsgi/))
* [bluepill](https://github.com/arya/bluepill)
* [Bottle.py](http://bottlepy.org/)
* [Chef](http://www.opscode.com/chef/) (chef-client, ohai, knife)
* [EC2](http://aws.amazon.com/ec2/) ([Amazon Linux AMI](http://aws.amazon.com/amazon-linux-ami/))
* [HAProxy](http://haproxy.1wt.eu/)
* [MongoDB](http://www.mongodb.org/) (server, [ruby](http://rubygems.org/gems/mongo) & [python](http://pypi.python.org/pypi/pymongo/) drivers)
* [Munin](http://munin-monitoring.org/)
* [Python](http://www.python.org/)
* [Ruby](http://www.ruby-lang.org/)
* [Siege](http://www.joedog.org/siege-home/)
* [Spiceweasel](https://github.com/mattray/spiceweasel)


Some of the more exotic pieces
------------------------------
* bluepill is a process manager, similar to SysV init, Upstart, supervisord, runit, etc.
* Bottle.py is a web micro-framework written in python.
* Munin is a performance metric gathering system.
* Siege creates web requests based on an input file for load testing.
* Spiceweasel generates Chef's knife commands from a config file


A picture
---------
![Diagram](http://www.diagrammr.com/png?key=dFoaUZxydGH)

Thanks to [diagrammr](http://www.diagrammr.com/).

Application
-----------
The Bottle.py application is a simplistic word counter, acts like a REST interface, where `/insert/<someword>` will add the word to the database and increment its counter.
    
The `/get/<someword>` will retrieve the word, the unique object ID, and the count of times this word was hit.

A call to `/toplist` will bring back the top 10 words that have been hit.

Customizations
==============
Nothing is perfect building blocks, but I tried to stay as close to the original as possible.

* `apache2` cookbook:
    * added a template for default system config and attribute for prefork mode
    * commented out the behavior of creating a default site. Ref: [COOK-1257](http://tickets.opscode.com/browse/COOK-1257)
* `bluepill` cookbook: added amazon linux platform
* `munin` cookbook:
    * added a platform-specific template to group servers by role
    * a minor directory permissions issue that exists with the munin 1.4.6 package, fixed in 1.4.7


Prep work
=========

Some EC2 security group work:

    ec2-create-group fullstack -d "Full-stack demo"
    # Allow
    ec2-authorize fullstack --protocol icmp --icmp-type-code=-1:-1 --source-or-dest-group fullstack
    # Could be shorter:
    # ec2-authorize fullstack -P icmp -t=-1:-1 -o fullstack
    ec2-authorize fullstack -P tcp -p 0-65535 -o fullstack
    ec2-authorize fullstack -P udp -p 0-65535 -o fullstack

    ec2-authorize fullstack -P tcp -p 22    # SSH
    ec2-authorize fullstack -P tcp -p 80    # HTTP
    
    # Optional, don't use in a production environment unless needed
    ec2-authorize fullstack -P tcp -p 22002 # HAProxy Stats
    ec2-authorize fullstack -P tcp -p 8080  # Webapp node

A chef server (open source or hosted) must exist, and `knife.rb` must be set up correctly with AWS credentials.
My personal one is excluded from the repo.

I recommend using a dedicated server/organization since the cleanup actions are destructive.

    current_dir = File.dirname(__FILE__)
    log_level                :info
    log_location             STDOUT
    node_name                "<my username>"
    client_key               "#{current_dir}/<my username>.pem"
    validation_client_name   "<organization-name>-validator"
    validation_key           "#{current_dir}/<organization-name>-validator.pem"
    chef_server_url          "https://api.opscode.com/organizations/<organization-name>"
    cache_type               'BasicFile'
    cache_options( :path => "#{ENV['HOME']}/.chef/checksums" )
    cookbook_path            ["#{current_dir}/../cookbooks"]
    # AWS credentials
    knife[:ssh_user]              = "ec2-user"
    knife[:ssh_identity_file]     = "#{current_dir}/../.aws/<key pair cert>.pem"
    knife[:aws_access_key_id]     = "<some key id>"
    knife[:aws_secret_access_key] = "<some secret string>"
    ### END ###

A Users Databag item must be placed in `data_bags/users/<username>.json`. An example is:
    
    {
      "id": "bofh",
      "ssh_keys": "ssh-rsa AAAAB3Nz...yhCw== bofh",
      "groups": "sysadmin",
      "uid": 2001,
      "shell": "\/bin\/bash",
      "comment": "BOFH",
      "openid": "bofh.myopenid.com"
    }
    
See the [users cookbook](http://community.opscode.com/cookbooks/users) for more help.

Launch
======

    spiceweasel fullspice.yml | bash


Some cool tricks
================

Get the top list of words:

    open http://`knife search node 'role:load_balancer' -a ec2.public_hostname |grep ec2.public_hostname | cut -f3 -d" "`/toplist

Munin Monitoring web console:

    open http://`knife search node 'role:monitoring' -a ec2.public_hostname |grep ec2.public_hostname | cut -f3 -d" "`

HAProxy web console:

    open http://`knife search node 'role:load_balancer' -a ec2.public_hostname |grep ec2.public_hostname | cut -f3 -d" "`:22002/

Find the mongodb replset primary:

    knife search node "fqdn:`knife ssh 'role:mongodb-replset-member' -a ec2.public_hostname 'curl http://localhost:28017/replSetGetStatus?text=1' | grep -B4 PRIMARY | grep name | awk '{print $4}' |cut -f1 -d":" | sed 's/^.\{1\}//' | uniq`" -a ec2

Note: This is probably overly complicated, but awesome. Probably better to have chef-client update the node record with the current state.

Kill the primary:

    knife ec2 server delete <instance-id from previous command>

Do something on all nodes:

    knife ssh '*:*' -a ec2.public_hostname 'sudo /sbin/service munin-node restart'


Cleanup
=======
Spiceweasel, in reverse:

    spiceweasel -d fullspice.yml | bash
    knife client bulk delete i-.*

That's all, folks!

Future enhancements
===================
* Allow for parallel spiceweasel creation - better mongodb replset creation
* More monitoring plugins for Munin - apache2, mongo, haproxy, etc
* Other monitoring services like ganglia, nagios, graphite
* More tweaking of performance - figure out the right mix of power of load to web

Credits
=======
* [Mike Fiedler](https://github.com/miketheman)
* [Daniel Crosta](https://github.com/dcrosta)