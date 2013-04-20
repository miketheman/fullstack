#
# Cookbook Name:: fullstack
# Recipe:: default
#
# Copyright 2012-2013, Mike Fiedler
#
# All rights reserved - Do Not Redistribute
#

# Load Datdog attributes from data bag
datadog = data_bag_item('credentials', 'datadog')
node.set['datadog']['api_key']         = datadog['api_key']
node.set['datadog']['application_key'] = datadog['application_key']
