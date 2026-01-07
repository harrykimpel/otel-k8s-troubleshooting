terraform {
  required_providers {
    newrelic = {
      source = "newrelic/newrelic"
    }
  }
}

provider "newrelic" {
  api_key    = var.NEW_RELIC_API_KEY
  account_id = var.NEW_RELIC_ACCOUNT_ID
  region     = var.NEW_RELIC_REGION
}

# Create Workload

resource "newrelic_workload" "ms-demo-workload" {
  name       = "OTel Demo Workload K8s Infra Troubleshooting"
  account_id = var.NEW_RELIC_ACCOUNT_ID
  entity_search_query {
    query = "(type LIKE 'KUBERNETES%')"
  }

  scope_account_ids = [var.NEW_RELIC_ACCOUNT_ID]
}


# Create Alerts based on APM Response Time & Kubernetes Cluster status

resource "newrelic_alert_policy" "otel-demo-alert-policy" {
  name = "OTel Demo All Alerts"
}

resource "newrelic_nrql_alert_condition" "ms-demo-pod-stability-condition" {
  account_id                     = var.NEW_RELIC_ACCOUNT_ID
  policy_id                      = newrelic_alert_policy.otel-demo-alert-policy.id
  type                           = "static"
  name                           = "POD Stability"
  description                    = "Alert when PODs are unstable"
  enabled                        = true
  violation_time_limit_seconds   = 3600
  fill_option                    = "static"
  fill_value                     = 1.0
  aggregation_window             = 60
  aggregation_method             = "event_flow"
  aggregation_delay              = 30
  expiration_duration            = 120
  open_violation_on_expiration   = true
  close_violations_on_expiration = true
  slide_by                       = 30

  nrql {
    query = "FROM Metric select uniqueCount(k8s.pod.name) as 'pods' WHERE k8s.cluster.name = 'instruqt-k3s' AND kube_pod_status_phase['latest'] = 1 AND phase = 'Failed' AND  created_by_kind != 'Job'"
  }

  critical {
    operator              = "above"
    threshold             = 3
    threshold_duration    = 300
    threshold_occurrences = "ALL"
  }
  warning {
    operator              = "above"
    threshold             = 0
    threshold_duration    = 120
    threshold_occurrences = "ALL"
  }
}

resource "newrelic_nrql_alert_condition" "ms-demo-cluster-stability-condition" {
  account_id                     = var.NEW_RELIC_ACCOUNT_ID
  policy_id                      = newrelic_alert_policy.otel-demo-alert-policy.id
  type                           = "static"
  name                           = "Cluster Stability"
  description                    = "Alert when Cluster is unstable"
  enabled                        = true
  violation_time_limit_seconds   = 3600
  fill_option                    = "static"
  fill_value                     = 0
  aggregation_window             = 60
  aggregation_method             = "event_flow"
  aggregation_delay              = 30
  expiration_duration            = 60
  open_violation_on_expiration   = true
  close_violations_on_expiration = true
  slide_by                       = 30

  nrql {
    query = "FROM Metric select filter(uniqueCount(k8s.node.name), where metricName = 'kube_node_status_condition' AND condition = 'Ready') / uniqueCount(k8s.node.name) * 100 as '% Nodes Ready' WHERE metricName = 'kube_node_status_condition' AND k8s.cluster.name = 'instruqt-k3s'"
  }

  critical {
    operator              = "below"
    threshold             = 100
    threshold_duration    = 300
    threshold_occurrences = "ALL"
  }
}

resource "newrelic_nrql_alert_condition" "ms-demo-container-stability-condition" {
  account_id                     = var.NEW_RELIC_ACCOUNT_ID
  policy_id                      = newrelic_alert_policy.otel-demo-alert-policy.id
  type                           = "static"
  name                           = "Container Stability"
  description                    = "Alert when Containers consume more CPU"
  enabled                        = true
  violation_time_limit_seconds   = 3600
  fill_option                    = "static"
  fill_value                     = 1.0
  aggregation_window             = 60
  aggregation_method             = "event_flow"
  aggregation_delay              = 30
  expiration_duration            = 120
  open_violation_on_expiration   = true
  close_violations_on_expiration = true
  slide_by                       = 30

  nrql {
    query = "FROM Metric select sum(kube_pod_container_status_restarts_total) as 'Container Restarts' WHERE k8s.cluster.name = 'instruqt-k3s'"
  }

  critical {
    operator                        = "above"
    threshold                       = 5
    threshold_duration              = 600
    threshold_occurrences           = "at_least_once"
    disable_health_status_reporting = false
  }

  warning {
    operator                        = "above"
    threshold                       = 1
    threshold_duration              = 600
    threshold_occurrences           = "at_least_once"
    disable_health_status_reporting = false
  }
}

resource "newrelic_nrql_alert_condition" "kubernetes_warning_events_by_reason" {
  account_id                   = var.NEW_RELIC_ACCOUNT_ID
  policy_id                    = newrelic_alert_policy.otel-demo-alert-policy.id
  type                         = "static"
  name                         = "Kubernetes Warning Events by Reason"
  enabled                      = true
  violation_time_limit_seconds = 259200

  nrql {
    query           = "from InfrastructureEvent, OtlpInfrastructureEvent select count(*) where category = 'kubernetes' and severity.text = 'Warning' facet k8s.event.reason WHERE k8s.cluster.name = 'instruqt-k3s' "
    data_account_id = 4472875
  }

  critical {
    operator              = "above"
    threshold             = 0
    threshold_duration    = 180
    threshold_occurrences = "at_least_once"
  }
  fill_option        = "none"
  aggregation_window = 60
  aggregation_method = "event_flow"
  aggregation_delay  = 120
}
