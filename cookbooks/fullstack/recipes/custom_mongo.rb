
# Add a munin plugins for MongoDB monitoring from this cookbook
%w{
  mongo_btree
  mongo_conn
  mongo_lock
  mongo_mem
  mongo_ops
}.each do |plugin_name|
  munin_plugin plugin_name do
    cookbook "fullstack"
    create_file true
  end
end
