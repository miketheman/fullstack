Description
===========
Sets up elements for the `fullstack` demo, such as the webapp and load generators.

Includes a potential fix for EPEL on Amazon Linux for [COOK-1262](http://tickets.opscode.com/browse/COOK-1262)

Requirements
============
Cookbooks:

* apache2
* bluepill
* python

A working mongoDB environment, as denoted by the `role:mongodb-replset-member` node attribute. This could theoretically be a single instance, but should be a Replica Set.

Attributes
==========

Usage
=====

Designed to run on AWS EC2 instances, using Amazon Linux AMI.

May run elsewhere, YMMV.

