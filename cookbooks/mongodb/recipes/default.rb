#
# Cookbook Name:: mongodb
# Recipe:: default
#
# Copyright 2012, Dan Crosta
#
# Public Domain
#

case node['platform']
  when "debian"
    apt_repository "10gen" do
      keyserver "keyserver.ubuntu.com"
      key "7F0CEB10"
      uri "http://downloads-distro.mongodb.org/repo/debian-sysvinit"
      distribution "dist"
      components ["10gen"]
      action :add
    end
  when "ubuntu"
    apt_repository "10gen" do
      keyserver "keyserver.ubuntu.com"
      key "7F0CEB10"
      uri "http://downloads-distro.mongodb.org/repo/ubuntu-upstart"
      distribution "dist"
      components ["10gen"]
      action :add
    end
  when "centos", "redhat", "fedora", "amazon", "scientific"
    yum_repository "10gen" do
      description "10gen RPM Repository"
      url "http://downloads-distro.mongodb.org/repo/redhat/os/$basearch"
      action :add
    end
end

package node['mongodb']['package_name'] do
  version node['mongodb']['version']
  action :install
end

service node['mongodb']['service_name'] do
  supports :start => true, :stop => true, :restart => true
end

keyfile = nil
if node['mongodb']['keyfile_contents']
  keyfile = "#{node['mongodb']['dbpath']}/keyfile"
  file keyfile do
    content node['mongodb']['keyfile_contents']
    owner node['mongodb']['user']
    group node['mongodb']['user']
    mode 0600
    action :create
  end
end

template node['mongodb']['configfile'] do
  source "mongodb.conf.erb"
  cookbook "mongodb"
  variables(
    :dbpath => node['mongodb']['dbpath'],
    :logpath => node['mongodb']['logpath'],
    :port => node['mongodb']['port'],
    :journal => node['mongodb']['journal'],
    :auth => node['mongodb']['auth'],
    :keyfile => keyfile,
    :nohttpinterface => node['mongodb']['nohttpinterface'],
    :rest => node['mongodb']['rest'],
    :replicaset => node['mongodb']['replicaset'],
    :fork => platform?("centos", "redhat", "fedora", "amazon"),
    :quiet => node['mongodb']['quiet']
  )
  owner "root"
  group "root"
  mode "0644"
  action :create
  notifies :restart, "service[#{node['mongodb']['service_name']}]", :immediately
end

