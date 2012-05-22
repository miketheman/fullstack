name "base"
description "Base role, applies to every client"
run_list %w{
  recipe[fullstack::ec2-epel]
  recipe[chef-client]
  recipe[ntp]
  recipe[sudo]
  recipe[users::sysadmins]
  recipe[munin::client]
}

# override_attributes()