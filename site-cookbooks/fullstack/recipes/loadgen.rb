#
# Cookbook Name:: fullstack
# Recipe:: loadgen
#
# Copyright 2012, Mike Fiedler
#
# All rights reserved - Do Not Redistribute
#

# For service control later in this recipe
include_recipe "bluepill"

approot = node['approot']

# Install siege
package "siege"

# Drop our random urls
directory approot do
  owner "root"
  group "root"
  mode 0777
  action :create
end

# Find the laod balancer's public hostname
if Chef::Config[:solo]
  Chef::Log.warn("This recipe uses search. Chef Solo does not support search.")
else
  lb = search(:node, "roles:load_balancer").first
end
Chef::Log.debug("LB Hostname found is: #{lb.ec2.public_hostname}")

# Create a randomized source file for siege to consume
# TODO: Convert ot a ruby_block sometime.
python "create random words" do
  user "root"
  code <<-EOH
import random
words = [x.strip() for x in file('/usr/share/dict/words') if x.strip()]
with file('#{approot}/urls.txt', 'w') as outfile:
    for word in random.sample(words, 50000):
        outfile.write("http://#{lb[0].ec2.public_hostname}/insert/%s\\n" % word)
  EOH
  not_if do
    File.exists?("#{approot}/urls.txt")
  end
end

# Start a siege against the webapp, background the process
# This is simply to link the correct binary, due to Omnibus
link "/usr/bin/bluepill" do
  to "/opt/opscode/embedded/bin/bluepill"
end

template "/etc/bluepill/siege.pill" do
  source "siege.pill.erb"
  variables(:approot => approot)
end

bluepill_service "siege" do
  action [:load, :start, :enable]
end
# Siege should now be running, kicking server's butts.
# If any major percentage of failures occur, bluepill will restart the attack.
