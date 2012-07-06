name "base"
description "Base role, applies to every client"
run_list %w{
  recipe[yum::epel]
  recipe[chef-client]
  recipe[ntp]
  recipe[sudo]
  recipe[users::sysadmins]
  recipe[munin::client]
  recipe[fullstack]
}

# override_attributes()