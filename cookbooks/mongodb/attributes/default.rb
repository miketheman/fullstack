
default[:mongodb][:version] = nil # when set to nil, most recent stable version

default[:mongodb][:port] = 27017
default[:mongodb][:journal] = true
default[:mongodb][:rest] = false
default[:mongodb][:nohttpinterface] = false
default[:mongodb][:replicaset] = nil
default[:mongodb][:quiet] = true

case platform
when "debian", "ubuntu"
  default[:mongodb][:configfile] = "/etc/mongodb.conf"
  default[:mongodb][:dbpath] = "/var/lib/mongodb"
  default[:mongodb][:logpath] = "/var/log/mongodb/mongodb.log"
  default[:mongodb][:user] = "mongodb"
  default[:mongodb][:group] = "mongodb"

  default[:mongodb][:package_name] = "mongodb-10gen"
  default[:mongodb][:service_name] = "mongodb"

when "centos", "redhat", "fedora", "amazon"
  default[:mongodb][:configfile] = "/etc/mongod.conf"
  default[:mongodb][:dbpath] = "/var/lib/mongo"
  default[:mongodb][:logpath] = "/var/log/mongo/mongod.log"
  default[:mongodb][:user] = "mongod"
  default[:mongodb][:group] = "mongod"

  default[:mongodb][:package_name] = "mongo-10gen-server"
  default[:mongodb][:service_name] = "mongod"

end

default[:mongodb][:auth] = false

# If set, the keyfile will be created in "${dbpath}/keyfile".
# This is necessary only when using authentication with a
# replica set (and will imply node[:mongodb][:auth] = true,
# even if you do not explicitly set it)
default[:mongodb][:keyfile_contents] = nil

