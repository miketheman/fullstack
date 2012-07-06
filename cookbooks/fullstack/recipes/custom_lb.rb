package "socat"

# Drop a special config file for the apache plugins
# TODO: make the entries based on apache node attributes
template "/etc/munin/plugin-conf.d/haproxy" do
  source "haproxy-munin-conf.erb"
  owner "root"
  group "root"
  mode 0644
  notifies :restart, resources(:service => "munin-node")
end

# Add a munin plugins for Apache monitoring from this cookbook
%w{
  haproxy_ng.in
}.each do |plugin_name|
  munin_plugin plugin_name do
    cookbook "fullstack"
    create_file true
  end
end


