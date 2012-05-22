fullstack
=========
Full-stack DevOps demo

The purpose of this is to demonstrate some great automation tools in orchestra.

Things used
-----------
(in alphabetic order)

* Amazon Web Services EC2
* Apache2
* Bottle.py
* Chef (chef-client, ohai, knife)
* HAProxy
* MongoDB (server, ruby & python drivers)
* Munin
* Python
* Ruby
* Spiceweasel


Framework
---------
OpsCode Chef is the primary driver for the infrastructure configuration management, with some add-ons.


Application
-----------
The Bottle.py application is a simplistic word counter, acts like a REST interface, where `/insert/<someword>` will add the word to the database and increment its counter.
    
The `/get/<someword>` will retrieve the word, the unique object ID, and the count of times this word was hit.

A call to `/toplist` will bring back the top 10 words that have been hit.

Customizations
==============
Nothing is perfect building blocks, but I tried to stay as close to the original as possible.

* `bluepill` cookbook: added amazon linux platform
* `apache2` cookbook: added a template for default system config and attribute for prefork mode


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

    TODO: insert example here

A Users Databag item must be placed in `data_bags/users/<username>.json`. An example is:
    
    TODO: insert example here
    

Some cool tricks
================

Munin Monitoring web console:

    open http://`knife search node 'role:monitoring' -a ec2.public_hostname |grep ec2.public_hostname | cut -f3 -d" "`

HAProxy web console:

    open http://`knife search node 'role:load_balancer' -a ec2.public_hostname |grep ec2.public_hostname | cut -f3 -d" "`:22002/

Do something on all nodes:

    knife ssh '*:*' -a ec2.public_hostname 'sudo /sbin/service munin-node restart'
    
Cleanup
=======
Spiceweasel, in reverse:

    spiceweasel -d coolspice.yml | bash
    knife client bulk delete i-.*

That's all, folks!

Credits
=======
* [Mike Fiedler](https://github.com/miketheman)
* [Daniel Crosta](https://github.com/dcrosta)