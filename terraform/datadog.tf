provider "datadog" {
  api_key = var.datadog_api_key
  app_key = var.datadog_app_key
  api_url = var.datadog_api_url
}

# Алерт на service check от http_check интеграции агента (install_datadog.yml)
resource "datadog_monitor" "wiki_http" {
  name    = "[Wiki.js] HTTP health check failed"
  type    = "service check"
  query   = "\"http.can_connect\".over(\"service:wiki\").by(\"host\").last(2).count_by_status()"
  message = <<-EOT
    Wiki.js не отвечает на HTTP-проверку с ВМ {{host.name}}.
    Проверьте контейнер: `docker ps` на server1/server2.
  EOT

  tags = ["env:dev", "service:wiki", "managed:terraform"]

  monitor_thresholds {
    critical = 1
    ok       = 1
    warning  = 1
  }

  notify_no_data    = false
  include_tags      = true
  new_group_delay   = 60
  renotify_interval = 0
}
