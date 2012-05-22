#
# Cookbook Name:: fullstack
# Recipe:: ec2-epel
#
# Copyright 2012, Mike Fiedler
#
# All rights reserved - Do Not Redistribute
#

# Enable the existing repo on EC2
execute "Enable EPEL Repo" do
  command "yum-config-manager --quiet --enable epel 2>&1 > /dev/null"
  not_if "yum-config-manager | grep epel" # Only enabled repos display
end
