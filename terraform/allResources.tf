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

# Create Service Levels for 2 services based on Latency & Error Rate

# data "newrelic_entity" "productcatalogservice" {
#   name = "productcatalogservice"
#   domain = "SERVICE"
#   type = "APPLICATION"
# }

# resource "newrelic_service_level" "productcatalogservice-latency-sl" {
#   guid = "${data.newrelic_entity.productcatalogservice.guid}"
#     name = "Online-Boutique ProductCatalogue Latency SL"
#     description = "Proportion of requests that are served faster than a threshold."

#     events {
#         account_id = var.NEW_RELIC_ACCOUNT_ID
#         valid_events {
#             from = "Transaction"
#             where = "appName = 'store-productcatalogservice' AND (transactionType='Web')"
#         }
#         good_events {
#             from = "Transaction"
#             where = "appName = 'store-productcatalogservice' AND (transactionType= 'Web') AND duration < 0.05"
#         }
#     }

#     objective {
#         target = 99.00
#         time_window {
#             rolling {
#                 count = 7
#                 unit = "DAY"
#             }
#         }
#     }
# }



# resource "newrelic_service_level" "productcatalogservice-error-sl" {
#   guid = "${data.newrelic_entity.productcatalogservice.guid}"
#     name = "Online-Boutique ProductCatalogue Error Rate SL"
#     description = "Proportion of requests that are failing"

#     events {
#         account_id = var.NEW_RELIC_ACCOUNT_ID
#         valid_events {
#             from = "Transaction"
#             where = "appName = 'store-productcatalogservice'"
#         }
#         bad_events {
#             from = "TransactionError"
#             where = "appName = 'store-productcatalogservice' AND error.expected IS FALSE"
#         }
#     }

#     objective {
#         target = 99.00
#         time_window {
#             rolling {
#                 count = 7
#                 unit = "DAY"
#             }
#         }
#     }
# }

# Create Alerts based on APM Response Time & Kubernetes Cluster status



resource "newrelic_alert_policy" "otel-demo-alert-policy" {
  name = "OTel Demo All Alerts"
}

# resource "newrelic_nrql_alert_condition" "ms-demo-latency-condition" {
#   account_id                     = var.NEW_RELIC_ACCOUNT_ID
#   policy_id                      = newrelic_alert_policy.otel-demo-alert-policy.id
#   type                           = "static"
#   name                           = "High Latency"
#   description                    = "Alert when transactions are taking too long"
#   enabled                        = true
#   violation_time_limit_seconds   = 3600
#   fill_option                    = "static"
#   fill_value                     = 1.0
#   aggregation_window             = 60
#   aggregation_method             = "event_flow"
#   aggregation_delay              = 30
#   expiration_duration            = 120
#   open_violation_on_expiration   = true
#   close_violations_on_expiration = true
#   slide_by                       = 30

#   nrql {
#     query = "SELECT average(duration) FROM Transaction where (appName = 'store-productcatalogservice' OR appName = 'store-frontend' OR appName = 'store-adservice' OR appName = 'store-cartservice' OR appName = 'store-checkoutservice' OR appName = 'store-currencyservice' OR appName = 'store-emailservice' OR appName = 'store-paymentservice' OR appName = 'store-recommendationservice' OR appName = 'store-shippingservice') FACET appName"
#   }

#   critical {
#     operator              = "above"
#     threshold             = 1
#     threshold_duration    = 120
#     threshold_occurrences = "ALL"
#   }

#   warning {
#     operator              = "above"
#     threshold             = 0.5
#     threshold_duration    = 120
#     threshold_occurrences = "ALL"
#   }
# }

# resource "newrelic_nrql_alert_condition" "ms-demo-sl-compliance-condition" {
#   account_id                     = var.NEW_RELIC_ACCOUNT_ID
#   policy_id                      = newrelic_alert_policy.otel-demo-alert-policy.id
#   type                           = "static"
#   name                           = "SLO Compliance"
#   description                    = "Alert when SL compliance drops below 95"
#   enabled                        = true
#   violation_time_limit_seconds   = 3600
#   fill_option                    = "static"
#   fill_value                     = 100
#   aggregation_window             = 60
#   aggregation_method             = "event_flow"
#   aggregation_delay              = 30
#   slide_by                       = 30

#   nrql {
#     query = "FROM Metric SELECT clamp_max(sum(newrelic.sli.good) / sum(newrelic.sli.valid) * 100, 100) as 'SLO compliance' FACET sli.guid"
#   }

#   critical {
#     operator              = "below"
#     threshold             = 90
#     threshold_duration    = 120
#     threshold_occurrences = "ALL"
#   }

#   warning {
#     operator              = "below"
#     threshold             = 95
#     threshold_duration    = 120
#     threshold_occurrences = "ALL"
#   }
# }

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


# data "newrelic_entity" "ms-demo-cartservice-app" {
#   name = "store-cartservice"
#   domain = "APM"
#   type = "APPLICATION"
# }

# resource "newrelic_service_level" "ms-demo-additem-latency-sl" {
#   guid = "${data.newrelic_entity.ms-demo-cartservice-app.guid}"
#     name = "Online-Boutique Add Item Key Txn Latency SL"
#     description = "Proportion of requests that are served faster than a threshold."

#     events {
#         account_id = var.NEW_RELIC_ACCOUNT_ID
#         valid_events {
#             from = "Transaction"
#             where = "name = 'WebTransaction/ASP/hipstershop.CartService/AddItem'"
#         }
#         good_events {
#             from = "Transaction"
#             where = "name = 'WebTransaction/ASP/hipstershop.CartService/AddItem' AND duration < 0.005"
#         }
#     }

#     objective {
#         target = 99.5
#         time_window {
#             rolling {
#                 count = 1
#                 unit = "DAY"
#             }
#         }
#     }
#}
