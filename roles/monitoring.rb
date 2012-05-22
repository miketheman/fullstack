name "monitoring"
description "The monitoring server"
run_list(
  "recipe[munin::server]"
)