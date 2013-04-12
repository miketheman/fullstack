name 'base'
description 'Base role, applies to every client'
run_list %w{
  yum::epel
  chef-client
  ntp
  sudo
  users::sysadmins
  fullstack::default
}
