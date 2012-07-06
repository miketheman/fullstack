#
# Cookbook Name:: fullstack
# Recipe:: default
#
# Copyright 2012, Mike Fiedler
#
# All rights reserved - Do Not Redistribute
#

# Handle an annoying behavior with Munin startup
directory "#{node['munin']['dbdir']}/plugin-state" do
  owner "nobody"
  group "munin"
  mode 0775
  notifies :restart, resources(:service => "munin-node")
end

# FIXME: This prevents the yum package checker from running, should be fixed in 1.4.7
file "#{node['munin']['dbdir']}/plugin-state/yum.state" do
  owner "nobody"
  group "munin"
  mode 0775
  action :create_if_missing
  notifies :restart, resources(:service => "munin-node")
end

# FIXME: This should allow iostat devices in a non-hardware environment to work
template "/etc/munin/plugin-conf.d/iostat" do
  source "iostat-munin-conf.erb"
  owner "root"
  group "root"
  mode 0644
  notifies :restart, resources(:service => "munin-node")
end

# Disable all the sendmail plugins
%w{
  sendmail_mailqueue
  sendmail_mailstats
  sendmail_mailtraffic
}.each do |plugin_name|
  munin_plugin plugin_name do
    enable false
  end
end
