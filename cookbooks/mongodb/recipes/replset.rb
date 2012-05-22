#
# Cookbook Name:: mongodb
# Recipe:: replset
#
# Copyright 2012, Dan Crosta
#
# Public Domain
#

include_recipe "mongodb"

# This needs chef 0.10.10, not included in omnibus installer yet.
# chef_gem "mongo"
gem_package "mongo" do
  action :install
end.run_action(:install)
Gem.clear_paths

ruby_block "configure-replica-set" do
  block do
    require "rubygems"
    require "mongo"

    if node[:mongodb][:replicaset].nil?
      Chef::Log.warn("recipe[mongodb::replset] applied to node without mongodb.replicaset attribute, skipping")
      next
    end

    # Retry 5 times, as we believe that there should
    # be a mongod accepting connections on localhost
    conn = nil
    10.times do |try|
      begin
        conn = Mongo::Connection.new(
          "localhost", node[:mongodb][:port],
          :slave_ok => true, :connect_timeout => 5)
      rescue
        delay = 2 ** (try + 1)
        Chef::Log.info("Failed to connect to mongodb, sleeping #{delay}, try #{try}/10")
        sleep(delay)
      end
    end

    if conn.nil?
      Chef::Log.warn("Could not connect to mongodb, giving up")
      next
    end

    rsstatus = conn["admin"]["$cmd"].find_one({"replSetGetStatus" => 1})

    # If we're already part of a replica set,
    # there's nothing left to do here.
    next if rsstatus["ok"] == 1


    # Otherwise, find out who we should consider
    # joining in our replica set, and who the
    # leader should be if there is no set yet
    # TODO: factor out role name
    # TODO: check for chef environment
    members = search("node", "role:mongodb-replset-member AND mongodb_replicaset:#{node[:mongodb][:replicaset]}").to_a
    if members.index { |host| host.name == node.name }.nil?
      members << node
    end
    members.sort! { |a,b| a.name <=> b.name }
    Chef::Log.debug("Members found from search: #{members}")

    # The leader is the first member of the search
    # results unless there is already a replica set
    # configured on one of the hosts, in which case
    # we look for the current primary and use that
    leader = members[0] unless members.empty?
    Chef::Log.debug("initial leader node name: #{leader.name}, fqdn: #{leader['fqdn']}")
    members.each do |host|
      begin
        cx = Mongo::Connection.new(
          host['fqdn'], host['mongodb']['port'],
          :slave_ok => true, :connect_timeout => 5)
      rescue Exception => e
        Chef::Log.debug("Could not connect to #{host['fqdn']}, error was: #{e}")
        next
      end
      ismaster = cx["admin"]["$cmd"].find_one({"isMaster" => 1})
      if ismaster["ok"] == 1
        if ismaster.include?("setName") and ismaster.include?("primary")
          leader = host if ismaster["setName"] == node[:mongodb][:replicaset] and ismaster["ismaster"] == true
          Chef::Log.debug("found PRIMARY, node name: #{host.name}, fqdn: #{host['fqdn']}")
        end
      end
      cx = nil
    end
    Chef::Log.debug("final leader name #{leader.name}, fqdn: #{leader['fqdn']}")

    # At this point, leader is a Chef::Node which is
    # either the first node of the members list (in which
    # case there is no replica set yet), or is the primary
    # of the existing replica set
    if leader.name == node.name
      # Then I am the set leader!
      Chef::Log.info("Creating a new replica set")
      config = {
        :_id => node[:mongodb][:replicaset],
        :version => 1,
        :members => []
      }
      members.each do |host|
        id = config[:members].length + 1
        config[:members] << {
          :_id => id,
          :host => "#{host['fqdn']}:#{host['mongodb']['port']}"
        }
      end

      Chef::Log.debug("Configuring replica set: #{config.inspect}")
      response = conn["admin"]["$cmd"].find_one({"replSetInitiate" => config})
      if response["ok"] != 1
        Chef::Log.warn("Something went wrong configuring replca set:")
        Chef::Log.warn("---------")
        Chef::Log.warn(response)
        Chef::Log.warn("---------")
        Chef::Log.warn("Manual intervention may be necessary.")
      end

    elsif rsstatus.include?("startupStatus") and rsstatus["startupStatus"] == 3
      Chef::Log.info("Adding #{node} to replica set")
      begin
        cx = Mongo::Connection.new(
          leader['fqdn'], leader['mongodb']['port'],
          :slave_ok => true, :connect_timeout => 5)
      rescue
        Chef::Log.warn("Could not connect to set leader on #{leader.fqdn}")
        next
      end

      config = cx['local']['system']['replset'].find_one()
      config["version"] = config["version"] + 1
      config["members"] << {
        :_id => (config["members"].length + 1), 
        :host => "#{node['fqdn']}:#{node['mongodb']['port']}"
      }

      begin
        cx['admin']['$cmd'].find_one({"replSetReconfig" => config})
      rescue
        # this could cause our connection to be
        # closed, and an error reported. ignore it.
        nil
      end

      # Since this may trigger an election, there's no way to
      # find out if it worked other than to wait a moment and
      # connect to ourselves to see if we've joined the set

      Chef::Log.info("Checking if we joined the replica set...")
      conn = nil
      5.times do |try|
        begin
          conn = Mongo::Connection.new(
            "localhost", node[:mongodb][:port],
            :slave_ok => true, :connect_timeout => 5)
        rescue
          delay = 2 ** (try + 1)
          Chef::Log.info("Failed to connect to mongodb, sleeping #{delay}, try #{try}/5")
          sleep(delay)
        end
      end
      if conn.nil?
        Chef::Log.error("Could not join replica set with leader at #{leader['fqdn']}")
        next
      end

      rsstatus = conn["admin"]["$cmd"].find_one({"replSetGetStatus" => 1})
      if rsstatus["ok"] == 1
        Chef::Log.info("Success!")
      end
    end
  end
end
