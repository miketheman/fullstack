name "webserver"
description "bottle.py webapp for fullstack"
run_list("recipe[fullstack::webapp]")
override_attributes(
  "apache" => {
    "listen_ports" => [ "8080", "443" ],
    "mpm_binary" => "httpd.worker"
  }
)