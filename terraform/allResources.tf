terraform {
  required_providers {
    newrelic = {
      source  = "newrelic/newrelic"
    }
  }
}

provider "newrelic" {
  api_key = var.NEW_RELIC_API_KEY
  account_id = var.NEW_RELIC_ACCOUNT_ID
  region = var.NEW_RELIC_REGION
}

# Create Workload

resource "newrelic_workload" "ms-demo-workload" {
    name = "OTel Demo Workload K8s Infra Troubleshooting"
    account_id = var.NEW_RELIC_ACCOUNT_ID
    entity_search_query {
        query = "(type LIKE 'KUBERNETES_%')" 
    }

    scope_account_ids =  [var.NEW_RELIC_ACCOUNT_ID]
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
    query = "from K8sPodSample SELECT latest(isReady) facet podName"
  }

  critical {
    operator              = "equals"
    threshold             = 0
    threshold_duration    = 300
    threshold_occurrences = "ALL"
  }
  warning {
    operator              = "equals"
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
    query = "SELECT uniqueCount(host) from K8sClusterSample where hostStatus != 'running' facet hostStatus, clusterName"
  }

  critical {
    operator              = "above"
    threshold             = 0
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
    query = "from K8sContainerSample SELECT average(cpuCoresUtilization) facet containerID"
  }

  critical {
    operator              = "above"
    threshold             = 50
    threshold_duration    = 120
    threshold_occurrences = "ALL"
  }
  warning {
    operator              = "above"
    threshold             = 40
    threshold_duration    = 120
    threshold_occurrences = "ALL"
  }
}
