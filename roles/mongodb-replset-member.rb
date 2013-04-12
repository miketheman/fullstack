name 'mongodb-replset-member'
description 'MongoDB database member in a Replica Set'
run_list(
  "mongodb::default",
  "mongodb::replset",
  "fullstack::custom_mongo"
)
default_attributes(
  'mongodb' => {
    'replicaset' => "fullstack"
  }
)
