#
# Cookbook Name:: fullstack
# Recipe:: webapp
#
# Copyright 2012, Mike Fiedler
#
# All rights reserved - Do Not Redistribute
#

include_recipe "apache2::mod_wsgi"
include_recipe "python::pip"

# Install dependencies for the webapp
%W{ pymongo bottle }.each do |egg|
  python_pip egg do
    action :install
  end
end

# disable default website
apache_site "default" do
  enable false
end

# Where my app will live
approot = "/opt/fullstack"

directory approot do
  owner "root"
  group "root"
  mode 0755
  action :create
end

# This is the wsgi controller, called in the apache config file
template "#{approot}/webapp.wsgi" do
  source "webapp.wsgi.erb"
  owner "root"
  group "root"
  mode 0755
  variables( :approot => approot )
end

# Define a WSGI reload resource
execute "reload wsgi" do
  command "touch #{approot}/webapp.wsgi"
  action :nothing
end

# This is the actual application.
# It could probably live in a repo somewhere, and be deployed via `deploy`, but
# since this app is very simplistic, I am deploying directly.
cookbook_file "#{approot}/webapp.py" do
  source "webapp.py"
  owner "root"
  group "root"
  mode 0755
  notifies :run, "execute[reload wsgi]"
end


# Build our config and connection details
mongo_hosts = []
replset_nodes = search("node", "role:mongodb-replset-member").each do |member|
    mongo_hosts << "#{member['fqdn']}:27017"
end
Chef::Log.debug("mongo_hosts is now: #{mongo_hosts.inspect}")

if !mongo_hosts.empty?
    mongo_uri = "mongodb://#{mongo_hosts.join(',')}/?replicaSet=fullstack"
else
    mongo_uri = "mongodb://localhost/"
end
Chef::Log.debug("mongo_uri is now: #{mongo_uri}")

template "#{approot}/local_settings.py" do
  source "local_settings.py.erb"
  owner "root"
  group "root"
  mode 0755
  variables(
    :mongo_replset_name => "fullstack",
    :mongo_uri => mongo_uri
  )
  notifies :run, "execute[reload wsgi]"
end  

web_app "fullstack" do
  server_name node['hostname']
  server_aliases [node['fqdn'], "fullstack.10gen.com"]
  template "fullstack_apache.conf.erb"
  docroot approot
  notifies :run, "execute[reload wsgi]"
end

