name "fullstack"
description "My FullStack environment"

override_attributes( 
  'chef_client' => {
    'init_style' => "init",
    'interval' => 180, # => 3 minutes for the demo, not realistic in prod
    'server_url' => "https://api.opscode.com/organizations/fullstack",
    'validation_client_name' => "fullstack-validator"    
  },
  'authorization' => {
    'sudo' => {
      "users" => ["ec2-user"],
      "groups" => ["sysadmins"],
      'passwordless' => true
    }
  },
  'haproxy' => {
    'member_max_connections' => 1000
  },
  'munin' => { 
    'server_auth_method' => 'htpasswd'
  },
  'siege' => {
    'concurrent' => 200
  }
)