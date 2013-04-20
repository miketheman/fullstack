
include_recipe 'datadog'

# Drop a configuration file for the agent
template '/etc/dd-agent/conf.d/haproxy.yaml' do
  owner 'dd-agent'
  mode 00644
  notifies :restart, "service[datadog-agent]"
end
