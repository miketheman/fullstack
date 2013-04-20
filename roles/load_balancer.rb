name 'load_balancer'
description 'haproxy load balancer'
run_list %w{
  haproxy::app_lb
  fullstack::custom_lb
}
override_attributes(
  'haproxy' => {
    'admin' => {
     'address_bind' => "0.0.0.0" # In prodcution, remove this for security
    },
    'app_server_role' => "webserver",
    'member_port' => "8080"
  },
)
