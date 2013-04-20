# Let's monitor mongo with datadog

include_recipe 'datadog'
include_recipe 'python'

package 'gcc' do
  action :install
end

python_pip 'pymongo' do
  action :install
end

# Drop a configuration file for the agent
template '/etc/dd-agent/conf.d/mongo.yaml' do
  owner 'dd-agent'
  mode 00644
  notifies :restart, "service[datadog-agent]"
end
