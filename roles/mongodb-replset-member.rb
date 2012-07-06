name "mongodb-replset-member"
description "MongoDB database member in a Replica Set"
run_list(
  "recipe[mongodb]",
  "recipe[mongodb::replset]",
  "recipe[fullstack::custom_mongo]"
)
default_attributes(
  'mongodb' => {
    'replicaset' => "fullstack"
    }
)