name "load_balancer"
description "haproxy load balancer"
run_list("recipe[haproxy::app_lb]", "fullstack::custom_lb")
override_attributes(
  "haproxy" => {
    "app_server_role" => "webserver",
    "member_port" => "8080"
  },
)