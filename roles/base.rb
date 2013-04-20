name 'base'
description 'Base role, applies to every client'
run_list %w{
  yum::epel
  chef-client::default
  ntp
  sudo
  users::sysadmins
  fullstack::default
  datadog::dd-handler
  datadog::dd-agent
}
