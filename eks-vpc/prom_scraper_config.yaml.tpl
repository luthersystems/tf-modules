global:
  scrape_interval: "${scrape_interval}"
  evaluation_interval: "${evaluation_interval}"
  external_labels:
    clusterArn: "${cluster_arn}"
    environment: "${environment}"

remote_write:
  - url: "${url}"
    sigv4:
      region: "${region}"
    queue_config:
      max_samples_per_send: 1000
      max_shards: 200
      capacity: 2500

scrape_configs:
  # Pod Exporter
  - job_name: pod_exporter
    kubernetes_sd_configs:
      - role: pod
    relabel_configs:
      - action: labelmap
        regex: __meta_kubernetes_pod_label_(.+)
      - source_labels: [__meta_kubernetes_namespace]
        target_label: namespace
      - source_labels: [__meta_kubernetes_pod_name]
        target_label: pod
    metric_relabel_configs:
      - source_labels: [__name__]
        regex: "pod_network_receive_bytes_total|pod_network_transmit_bytes_total|pod_cpu_usage_seconds_total|pod_memory_usage_bytes"
        action: keep
      - source_labels: [__name__]
        regex: ".*"
        action: drop  # Drop any unfiltered metrics to minimize ingestion

  # cAdvisor
  - job_name: cadvisor
    scheme: https
    authorization:
      credentials_file: /var/run/secrets/kubernetes.io/serviceaccount/token
    kubernetes_sd_configs:
      - role: node
    relabel_configs:
      - action: labelmap
        regex: __meta_kubernetes_node_label_(.+)
      - replacement: kubernetes.default.svc:443
        target_label: __address__
      - source_labels: [__meta_kubernetes_node_name]
        regex: (.+)
        target_label: __metrics_path__
        replacement: /api/v1/nodes/$1/proxy/metrics/cadvisor
    metric_relabel_configs:
      - source_labels: [__name__]
        regex: "node_cpu_seconds_total|node_memory_MemAvailable_bytes|node_memory_MemTotal_bytes|node_memory_MemFree_bytes"
        action: keep  # Retain critical node metrics
      - source_labels: [__name__]
        regex: ".*"
        action: drop  # Drop any unfiltered metrics

  # Kubernetes API Servers
  - bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
    job_name: kubernetes-apiservers
    kubernetes_sd_configs:
      - role: endpoints
    relabel_configs:
      - action: keep
        regex: default;kubernetes;https
        source_labels:
          - __meta_kubernetes_namespace
          - __meta_kubernetes_service_name
          - __meta_kubernetes_endpoint_port_name
    scheme: https
    metric_relabel_configs:
      - source_labels: [__name__]
        regex: "apiserver_request_total|apiserver_request_duration_seconds_bucket|apiserver_response_sizes"
        action: keep  # Retain key API server metrics
      - source_labels: [__name__]
        regex: ".*"
        action: drop

  # Kubernetes Proxy
  - job_name: kube-proxy
    honor_labels: true
    kubernetes_sd_configs:
      - role: pod
    relabel_configs:
      - action: keep
        source_labels:
          - __meta_kubernetes_namespace
          - __meta_kubernetes_pod_name
        separator: "/"
        regex: "kube-system/kube-proxy.+"
      - source_labels:
          - __address__
        action: replace
        target_label: __address__
        regex: (.+?)(\\:\\d+)?
        replacement: $1:10249
    metric_relabel_configs:
      - source_labels: [__name__]
        regex: "kubeproxy_sync_proxy_rules_latency_seconds"
        action: keep  # Keep only important kube-proxy metrics
      - source_labels: [__name__]
        regex: ".*"
        action: drop
