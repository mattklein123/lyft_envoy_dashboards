{% set envoy_gauge_divisor = 120 %}

{% macro ingress_stats(remote_service_cluster, canary=False, error_rate_percent_5xx=False, collapse=False) %}
          - title: {{remote_service_cluster}} INGRESS
            collapse: {{ collapse }}
            showTitle: True
            panels:
              - title: Ingress CPS / RPS
                datasource: wavefront
                targets:
                  - target: ts($environment.infra.aws.ec2.asg.envoy.http.ingress_http.rq_total.count.rate, asg={{remote_service_cluster}} and window=60)
                    name: RPS
                  - target: ts($environment.infra.aws.ec2.asg.envoy.http.ingress_http.downstream_cx_total.count.rate, asg={{remote_service_cluster}} and window=60)
                    name: CPS
                  {% if canary %}
                  - target: ts(production.infra.aws.ec2.asg.envoy.http.ingress_http.rq_total.instance.count.rate, asg={{remote_service_cluster}} and window=60)
                    name: canary RPS
                  - target: ts(production.infra.aws.ec2.asg.envoy.http.ingress_http.downstream_cx_total.instance.count.rate, asg={{remote_service_cluster}} and window=60)
                    name: canary CPS
                  {% endif %}
              - title: Total Connections / Requests
                datasource: wavefront
                targets:
                  - target: ts($environment.infra.aws.ec2.asg.envoy.http.ingress_http.downstream_cx_active.gauge.sum, asg={{remote_service_cluster}} and window=60)/{{ envoy_gauge_divisor }}
                    name: ingress connections
                  - target: ts($environment.infra.aws.ec2.asg.envoy.http.ingress_http.downstream_rq_active.gauge.sum, asg={{remote_service_cluster}} and window=60)/{{ envoy_gauge_divisor }}
                    name: ingress requests
                  {% if canary %}
                  - target: ts(production.infra.aws.ec2.asg.envoy.http.ingress_http.downstream_cx_active.instance.gauge.sum, asg={{remote_service_cluster}} and window=60)/{{ envoy_gauge_divisor }}
                    name: canary ingress connections
                  - target: ts(production.infra.aws.ec2.asg.envoy.http.ingress_http.downstream_rq_active.instance.gauge.sum, asg={{remote_service_cluster}} and window=60)/{{ envoy_gauge_divisor }}
                    name: canary ingress requests
                  {% endif %}
              - title: Response Time
                datasource: wavefront
                targets:
                  - target: ts($environment.infra.aws.ec2.asg.envoy.http.ingress_http.downstream_rq_time.timer.p50, asg={{remote_service_cluster}} and window=60)
                    name: p50
                  - target: ts($environment.infra.aws.ec2.asg.envoy.http.ingress_http.downstream_rq_time.timer.p95, asg={{remote_service_cluster}} and window=60)
                    name: p95
                  - target: ts($environment.infra.aws.ec2.asg.envoy.http.ingress_http.downstream_rq_time.timer.p99, asg={{remote_service_cluster}} and window=60)
                    name: p99
                  {% if canary %}
                  - target: ts(production.infra.aws.ec2.asg.envoy.http.ingress_http.downstream_rq_time.instance.timer.p50, asg={{remote_service_cluster}} and window=60)
                    name: canary p50
                  - target: ts(production.infra.aws.ec2.asg.envoy.http.ingress_http.downstream_rq_time.instance.timer.p95, asg={{remote_service_cluster}} and window=60)
                    name: canary p95
                  - target: ts(production.infra.aws.ec2.asg.envoy.http.ingress_http.downstream_rq_time.instance.timer.p99, asg={{remote_service_cluster}} and window=60)
                    name: canary p99
                  {% endif %}
                y_formats:
                  - ms
                  - short
              - title: Success Rate (non-5xx responses)
                datasource: wavefront
                targets:
                  - target: 100 * (1 - rawsum(ts($environment.infra.aws.ec2.asg.envoy.http.ingress_http.downstream_rq_5xx.count.rate, asg={{remote_service_cluster}} and window=60))/rawsum(ts($environment.infra.aws.ec2.asg.envoy.http.ingress_http.downstream_rq_*xx.count.rate, asg={{remote_service_cluster}} and window=60)))
                    name: prod
                  {% if canary %}
                  - target: 100 * (1 - rawsum(ts(production.infra.aws.ec2.asg.envoy.http.ingress_http.downstream_rq_5xx.instance.count.rate, asg={{remote_service_cluster}} and window=60))/rawsum(ts(production.infra.aws.ec2.asg.envoy.http.ingress_http.downstream_rq_*xx.count.rate, asg={{remote_service_cluster}} and window=60)))
                    name: canary
                  {% endif %}
                  {% if error_rate_percent_5xx %}
                  - target: 100.0 - error_rate_percent_5xx
                    name: min
                  {% endif %}
                y_formats:
                  - percent
              - title: 4xx %
                datasource: wavefront
                targets:
                   - target: 100 * rawsum(ts($environment.infra.aws.ec2.asg.envoy.http.ingress_http.downstream_rq_4xx.count.rate, asg={{remote_service_cluster}} and window=60))/rawsum(ts($environment.infra.aws.ec2.asg.envoy.http.ingress_http.downstream_rq_*xx.count.rate, asg={{remote_service_cluster}} and window=60))
                     name: prod
                  {% if canary %}
                   - target: 100 * rawsum(ts(production.infra.aws.ec2.asg.envoy.http.ingress_http.downstream_rq_4xx.instance.count.rate, asg={{remote_service_cluster}} and window=60))/rawsum(ts(production.infra.aws.ec2.asg.envoy.http.ingress_http.downstream_rq_*xx.count.rate, asg={{remote_service_cluster}} and window=60))
                     name: canary
                  {% endif %}
                y_formats:
                  - percent
              - title: Local Service Errors
                datasource: wavefront
                targets:
                  - target: ts($environment.infra.aws.ec2.asg.envoy.http.ingress_http.downstream_cx_destroy_local_active_rq.count.rate, asg={{remote_service_cluster}} and window=60)
                    name: cx closed local with active rq
                  - target: ts($environment.infra.aws.ec2.asg.envoy.cluster.local_service.upstream_cx_destroy_remote_with_active_rq.count.rate, asg={{remote_service_cluster}} and window=60)
                    name: cx closed remote with active rq
                  - target: ts($environment.infra.aws.ec2.asg.envoy.cluster.local_service.upstream_cx_connect_timeout.count.rate, asg={{remote_service_cluster}} and window=60)
                    name: connect timeout
                  - target: ts($environment.infra.aws.ec2.asg.envoy.cluster.local_service.upstream_rq_pending_failure_eject.count.rate, asg={{remote_service_cluster}} and window=60)
                    name: pending failure ejection
                  - target: ts($environment.infra.aws.ec2.asg.envoy.cluster.local_service.upstream_rq_pending_overflow.count.rate, asg={{remote_service_cluster}} and window=60)
                    name: pending overflow
                  {% if canary %}
                  - target: ts(production.infra.aws.ec2.asg.envoy.http.ingress_http.downstream_cx_destroy_local_active_rq.instance.count.rate, asg={{remote_service_cluster}} and window=60)
                    name: canary cx closed local with active rq
                  - target: ts(production.infra.aws.ec2.asg.envoy.cluster.local_service.upstream_cx_destroy_remote_with_active_rq.instance.count.rate, asg={{remote_service_cluster}} and window=60)
                    name: canary cx closed remote with active rq
                  - target: ts(production.infra.aws.ec2.asg.envoy.cluster.local_service.upstream_cx_connect_timeout.instance.count.rate, asg={{remote_service_cluster}} and window=60)
                    name: canary connect timeout
                  - target: ts(production.infra.aws.ec2.asg.envoy.cluster.local_service.upstream_rq_pending_failure_eject.instance.count.rate, asg={{remote_service_cluster}} and window=60)
                    name: canary pending failure ejection
                  - target: ts(production.infra.aws.ec2.asg.envoy.cluster.local_service.upstream_rq_pending_overflow.instance.count.rate, asg={{remote_service_cluster}} and window=60)
                    name: canary pending overflow
                  {% endif %}
              - title: Local Service GRPC Errors
                datasource: wavefront
                targets:
                  - target: ts($environment.infra.aws.ec2.asg.envoy.cluster.local_service_grpc.upstream_cx_destroy_remote_with_active_rq.count.rate, asg={{remote_service_cluster}} and window=60)
                    name: cx closed remote with active rq
                  - target: ts($environment.infra.aws.ec2.asg.envoy.cluster.local_service_grpc.upstream_cx_connect_timeout.count.rate, asg={{remote_service_cluster}} and window=60)
                    name: connect timeout
                  - target: ts($environment.infra.aws.ec2.asg.envoy.cluster.local_service_grpc.upstream_rq_pending_failure_eject.count.rate, asg={{remote_service_cluster}} and window=60)
                    name: pending failure ejection
                  - target: ts($environment.infra.aws.ec2.asg.envoy.cluster.local_service_grpc.upstream_rq_pending_overflow.count.rate, asg={{remote_service_cluster}} and window=60)
                    name: pending overflow
                  {% if canary %}
                  - target: ts(production.infra.aws.ec2.asg.envoy.cluster.local_service_grpc.upstream_cx_destroy_remote_with_active_rq.instance.count.rate, asg={{remote_service_cluster}} and window=60)
                    name: canary cx closed remote with active rq
                  - target: ts(production.infra.aws.ec2.asg.envoy.cluster.local_service_grpc.upstream_cx_connect_timeout.instance.count.rate, asg={{remote_service_cluster}} and window=60)
                    name: canary connect timeout
                  - target: ts(production.infra.aws.ec2.asg.envoy.cluster.local_service_grpc.upstream_rq_pending_failure_eject.instance.count.rate, asg={{remote_service_cluster}} and window=60)
                    name: canary pending failure ejection
                  - target: ts(production.infra.aws.ec2.asg.envoy.cluster.local_service_grpc.upstream_rq_pending_overflow.instance.count.rate, asg={{remote_service_cluster}} and window=60)
                    name: canary pending overflow
                  {% endif %}
              {{  downstream_requests(remote_service_cluster) }}
              - title: Flow Control
                datasource: wavefront
                span: 3
                targets:
                  - target: 'ts($environment.infra.aws.ec2.asg.envoy.http.ingress_http.downstream_flow_control_paused_reading_total.count.rate, asg={{remote_service_cluster}} and window=60)'
                    name: total paused reads
                  - target: 'ts($environment.infra.aws.ec2.asg.envoy.http.ingress_http.downstream_flow_control_resumed_reading_total.count.rate, asg={{remote_service_cluster}} and window=60)'
                    name: total paused reads
                  {% if canary %}
                  - target: ts(production.infra.aws.ec2.asg.envoy.http.ingress_http.downstream_flow_control_paused_reading_total.instance.count.rate, asg={{remote_service_cluster}} and window=60)
                    name: canary total paused reads
                  - target: ts(production.infra.aws.ec2.asg.envoy.http.ingress_http.downstream_flow_control_resumed_reading_total.instance.count.rate, asg={{remote_service_cluster}} and window=60)
                    name: canary total paused reads
                  {% endif %}
              - title: Overly Large Request and Response Bodies
                datasource: wavefront
                span: 3
                targets:
                  - target: ts($environment.infra.aws.ec2.asg.envoy.http.ingress_http.downstream_rq_too_large.count.rate, asg={{remote_service_cluster}} and window=60)
                    name: Request body too large
                  - target: ts($environment.infra.aws.ec2.asg.envoy.http.ingress_http.rs_too_large.count.rate, asg={{remote_service_cluster}} and window=60)
                    name: Response body too large
                  {% if canary %}
                  - target: ts(production.infra.aws.ec2.asg.envoy.http.ingress_http.downstream_rq_too_large.instance.count.rate, asg={{remote_service_cluster}} and window=60)
                    name: canary request body too large
                  - target: ts(production.infra.aws.ec2.asg.envoy.http.ingress_http.rs_too_large.instance.count.rate, asg={{remote_service_cluster}} and window=60)
                    name: canary response body too large
                  {% endif %}
{% endmacro %}

{% macro egress_stats(originating_service, destination_service, canary=False, show_grpc=True, collapse=False) %}
          - title: 'Egress from {{originating_service}} to {{destination_service}}'
            collapse: {{ collapse }}
            showTitle: True
            panels:
              - title: Egress CPS / RPS
                datasource: wavefront
                targets:
                  - target: ts($environment.infra.aws.ec2.asg.envoy.cluster.{{destination_service}}.upstream_cx_total.count.rate, asg={{originating_service}} and window=60)
                    name: egress CPS
                  - target: ts($environment.infra.aws.ec2.asg.envoy.cluster.{{destination_service}}.upstream_rq_total.count.rate, asg={{originating_service}} and window=60)
                    name: egress RPS
                  - target: ts($environment.infra.aws.ec2.asg.envoy.cluster.{{destination_service}}.upstream_rq_pending_total.count.rate, asg={{originating_service}} and window=60)
                    name: pending req to
                  - target: ts($environment.infra.aws.ec2.asg.envoy.cluster.{{destination_service}}.lb_healthy_panic.count.rate, asg={{originating_service}} and window=60)
                    name: lb healthy panic RPS
              - title: Total Connections / Requests
                datasource: wavefront
                targets:
                  - target: ts($environment.infra.aws.ec2.asg.envoy.cluster.{{destination_service}}.upstream_cx_active.gauge.sum, asg={{originating_service}} and window=60)/{{ envoy_gauge_divisor }}
                    name: connections
                  - target: ts($environment.infra.aws.ec2.asg.envoy.cluster.{{destination_service}}.upstream_rq_active.gauge.sum, asg={{originating_service}} and window=60)/{{ envoy_gauge_divisor }}
                    name: requests
                  - target: ts($environment.infra.aws.ec2.asg.envoy.cluster.{{destination_service}}.upstream_rq_pending_active.gauge.sum, asg={{originating_service}} and window=60)/{{ envoy_gauge_divisor }}
              - title: Cluster Membership
                datasource: wavefront
                targets:
                  - target: ts($environment.infra.aws.ec2.asg.envoy.cluster.{{destination_service}}.membership_change.count.sum, asg={{originating_service}} and window=60)
                    name: membership changes
                  - target: ts($environment.infra.aws.ec2.asg.envoy.cluster.{{destination_service}}.membership_total.gauge.mean, asg={{originating_service}} and window=60)
                    name: total membership
                  - target: ts($environment.infra.aws.ec2.asg.envoy.cluster.{{destination_service}}.outlier_detection.ejections_active.gauge.mean, asg={{originating_service}} and window=60)
                    name: outlier ejections active
                  - target: ts($environment.infra.aws.ec2.asg.envoy.cluster.{{destination_service}}.membership_healthy.gauge.mean, asg={{originating_service}} and window=60)
                    name: healthy members (active HC and outlier)
                  - target: ts($environment.infra.aws.ec2.asg.envoy.cluster.{{destination_service}}.health_check.healthy.gauge.mean, asg={{originating_service}} and window=60)
                    name: healthy members (active HC only)
              - title: Upstream Response Time
                datasource: wavefront
                targets:
                  - target: ts($environment.infra.aws.ec2.asg.envoy.cluster.{{destination_service}}.upstream_rq_time.timer.p50, asg={{originating_service}} and window=60)
                    name: p50
                  - target: ts($environment.infra.aws.ec2.asg.envoy.cluster.{{destination_service}}.upstream_rq_time.timer.p95, asg={{originating_service}} and window=60)
                    name: p95
                  - target: ts($environment.infra.aws.ec2.asg.envoy.cluster.{{destination_service}}.upstream_rq_time.timer.p99, asg={{originating_service}} and window=60)
                    name: p99
                  {% if canary %}
                  - target: ts(production.infra.aws.ec2.asg.envoy.cluster.{{destination_service}}.upstream_rq_time.instance.timer.p50, asg={{originating_service}} and window=60)
                    name: canary p50
                  - target: ts(production.infra.aws.ec2.asg.envoy.cluster.{{destination_service}}.upstream_rq_time.instance.timer.p95, asg={{originating_service}} and window=60)
                    name: canary p95
                  - target: ts(production.infra.aws.ec2.asg.envoy.cluster.{{destination_service}}.upstream_rq_time.instance.timer.p99, asg={{originating_service}} and window=60)
                    name: canary p99
                  {% endif %}
                y_formats:
                  - ms
                  - short
              - title: Success Rate (non-5xx responses)
                datasource: wavefront
                targets:
                  - target: 100 * (1 - (rawsum(ts($environment.infra.aws.ec2.asg.envoy.cluster.{{destination_service}}.upstream_rq_5xx.count.rate, asg={{originating_service}} and window=60))/rawsum(ts($environment.infra.aws.ec2.asg.envoy.cluster.{{destination_service}}.upstream_rq_*xx.count.rate, asg={{originating_service}} and window=60))))
                    name: prod
                {% if canary %}
                  - target: 100 * (1 - rawsum(ts(production.infra.aws.ec2.asg.envoy.cluster.{{destination_service}}.upstream_rq_5xx.instance.count.rate, asg={{originating_service}} and window=60))/rawsum(ts(production.infra.aws.ec2.asg.envoy.cluster.{{destination_service}}.upstream_rq_*xx.instance.count.rate, asg={{originating_service}} and window=60)))
                    name: canary
                {% endif %}
                y_formats:
                  - percent
              - title: 4xx %
                datasource: wavefront
                targets:
                  - target: 100 * (rawsum(ts($environment.infra.aws.ec2.asg.envoy.cluster.{{destination_service}}.upstream_rq_4xx.count.rate, asg={{originating_service}} and window=60))/rawsum(ts($environment.infra.aws.ec2.asg.envoy.cluster.{{destination_service}}.upstream_rq_*xx.count.rate, asg={{originating_service}} and window=60)))
                    name: prod
                {% if canary %}
                  - target: 100 * (rawsum(ts($environment.infra.aws.ec2.asg.envoy.cluster.{{destination_service}}.upstream_rq_4xx.instance.count.rate, asg={{originating_service}} and window=60))/rawsum(ts($environment.infra.aws.ec2.asg.envoy.cluster.{{destination_service}}.upstream_rq_*xx.instance.count.rate, asg={{originating_service}} and window=60)))
                    name: canary
                {% endif %}
                y_formats:
                  - percent
              - title: Upstream Request Errors
                datasource: wavefront
                targets:
                  - target: ts($environment.infra.aws.ec2.asg.envoy.cluster.{{destination_service}}.upstream_cx_connect_timeout.count.rate, asg={{originating_service}} and window=60)
                    name: connect timeout
                  - target: ts($environment.infra.aws.ec2.asg.envoy.cluster.{{destination_service}}.upstream_rq_pending_failure_eject.count.rate, asg={{originating_service}} and window=60)
                    name: pending failure ejection
                  - target: ts($environment.infra.aws.ec2.asg.envoy.cluster.{{destination_service}}.upstream_rq_pending_overflow.count.rate, asg={{originating_service}} and window=60)
                    name: pending overflow
                  - target: ts($environment.infra.aws.ec2.asg.envoy.cluster.{{destination_service}}.upstream_rq_timeout.count.rate, asg={{originating_service}} and window=60)
                    name: request timeout
                  - target: ts($environment.infra.aws.ec2.asg.envoy.cluster.{{destination_service}}.upstream_rq_per_try_timeout.count.rate, asg={{originating_service}} and window=60)
                    name: per try request timeout
                  - target: ts($environment.infra.aws.ec2.asg.envoy.cluster.{{destination_service}}.upstream_rq_rx_reset.count.rate, asg={{originating_service}} and window=60)
                    name: request reset
                  - target: ts($environment.infra.aws.ec2.asg.envoy.cluster.{{destination_service}}.upstream_cx_destroy_local_with_active_rq.count.rate, asg={{originating_service}} and window=60)
                    name: destroy initialized from originating service
                  - target: ts($environment.infra.aws.ec2.asg.envoy.cluster.{{destination_service}}.upstream_cx_destroy_remote_with_active_rq.count.rate, asg={{originating_service}} and window=60)
                    name: destroy initialized from destination service
                  - target: ts($environment.infra.aws.ec2.asg.envoy.cluster.{{destination_service}}.upstream_rq_maintenance_mode.count.rate, asg={{originating_service}} and window=60)
                    name: request failed maintenance mode
              - title: Upstream Request Retry
                datasource: wavefront
                targets:
                  - target: ts($environment.infra.aws.ec2.asg.envoy.cluster.{{destination_service}}.upstream_rq_retry.count.rate, asg={{originating_service}} and window=60)
                    name: request retry
                  - target: ts($environment.infra.aws.ec2.asg.envoy.cluster.{{destination_service}}.upstream_rq_retry_success.count.rate, asg={{originating_service}} and window=60)
                    name: request retry success
                  - target: ts($environment.infra.aws.ec2.asg.envoy.cluster.{{destination_service}}.upstream_rq_retry_overflow.count.rate, asg={{originating_service}} and window=60)
                    name: request retry overflow
              - title: Upstream Flow Control
                span: 3
                datasource: wavefront
                targets: 
                  - target: 'ts($environment.infra.aws.ec2.asg.envoy.cluster.{{destination_service}}.upstream_flow_control_paused_reading_total.count.rate, asg={{originating_service}} and window=60)'
                    name: paused reading from destination service
                  - target: 'ts($environment.infra.aws.ec2.asg.envoy.cluster.{{destination_service}}.upstream_flow_control_resumed_reading_total.count.rate, asg={{originating_service}} and window=60)'
                    name: resumed reading from destination service
                  - target: 'ts($environment.infra.aws.ec2.asg.envoy.cluster.{{destination_service}}.upstream_flow_control_backed_up_total.count.rate, asg={{originating_service}} and window=60)'
                    name: paused reading from originating service
                  - target: 'ts($environment.infra.aws.ec2.asg.envoy.cluster.{{destination_service}}.upstream_flow_control_drained_total.count.rate, asg={{originating_service}} and window=60)'
                    name: resumed reading from originating service
              - title: Outlier Detection
                span: 3
                datasource: wavefront
                targets:
                  - target: 'ts($environment.infra.aws.ec2.asg.envoy.cluster.{{destination_service}}.outlier_detection.ejections_total.count.sum, asg={{originating_service}} and window=60)'
                    name: 'Total ejections'
                  - target: 'ts($environment.infra.aws.ec2.asg.envoy.cluster.{{destination_service}}.outlier_detection.ejections_overflow.count.sum, asg={{originating_service}} and window=60)'
                    name: 'Total ejection overflows'
              {% if show_grpc %}
              - title: GRPC Success Rates per method
                span: 3
                datasource: wavefront
                targets:
                  - target: 100*(rawsum(taggify(align(1m,default(0, ts($environment.infra.aws.ec2.asg.envoy.cluster.{{destination_service}}.grpc.pb.lyft.*.success.count.sum, asg={{originating_service}} and window=60))), metric, methodname, 13), methodname)) / (rawsum(taggify(align(1m,default(0, ts($environment.infra.aws.ec2.asg.envoy.cluster.{{destination_service}}.grpc.pb.lyft.*.total.count.sum, asg={{originating_service}} and window=60))), metric, methodname, 13), methodname))
                    regexes:
                      - regex: "methodname='([^']+)'"
                        replacement: $1
                y_formats:
                  - percent
              - title: GRPC RPS per method
                span: 3
                datasource: wavefront
                targets:
                  - target: taggify(ts($environment.infra.aws.ec2.asg.envoy.cluster.{{destination_service}}.grpc.pb.lyft.*.total.count.rate, asg={{originating_service}} and window=60), metric, methodname, 13)
                    regexes:
                      - regex: "methodname='([^']+)'"
                        replacement: $1
              {% endif %}
          - title: 'CROSS ZONE EGRESS from {{originating_service}} to {{destination_service}}'
            collapse: True
            panels:
              - title: RPS
                datasource: wavefront
                targets:
                  - target: 'rawsum(taggify(taggify(ts($environment.infra.aws.ec2.asg.envoy.cluster.{{destination_service}}.zone.*.upstream_rq_*xx.count.rate, asg={{originating_service}} and window=60), metric, from_zone, 9), metric, to_zone, 10), from_zone, to_zone)'
                    regexes:
                      - regex: "from_zone='([^']+)'.*to_zone='([^']+)'"
                        replacement: "$1.$2"
              - title: P50 LATENCY
                datasource: wavefront
                targets:
                  - target: 'rawavg(taggify(taggify(ts($environment.infra.aws.ec2.asg.envoy.cluster.{{destination_service}}.zone.*.upstream_rq_time.timer.p50, asg={{originating_service}} and window=60), metric, from_zone, 9), metric, to_zone, 10), from_zone, to_zone)'
                    regexes:
                      - regex: "from_zone='([^']+)'.*to_zone='([^']+)'"
                        replacement: "$1.$2.p50"
              - title: P95 LATENCY
                datasource: wavefront
                targets:
                  - target: 'rawavg(taggify(taggify(ts($environment.infra.aws.ec2.asg.envoy.cluster.{{destination_service}}.zone.*.upstream_rq_time.timer.p95, asg={{originating_service}} and window=60), metric, from_zone, 9), metric, to_zone, 10), from_zone, to_zone)'
                    regexes:
                      - regex: "from_zone='([^']+)'.*to_zone='([^']+)'"
                        replacement: "$1.$2.p95"
              - title: P99 LATENCY
                datasource: wavefront
                targets:
                  - target: 'rawavg(taggify(taggify(ts($environment.infra.aws.ec2.asg.envoy.cluster.{{destination_service}}.zone.*.upstream_rq_time.timer.p99, asg={{originating_service}} and window=60), metric, from_zone, 9), metric, to_zone, 10), from_zone, to_zone)'
                    regexes:
                      - regex: "from_zone='([^']+)'.*to_zone='([^']+)'"
                        replacement: "$1.$2.p99"
{% endmacro %}

{% macro circuit_breaking(originating_service, destination_service) %}
          - title: 'Circuit breaking'
            collapse: True
            showTitle: True
            panels:
              - title: {{destination_service}} connection overflow
                datasource: wavefront
                targets:
                  - target: ts($environment.infra.aws.ec2.instance.envoy.cluster.local_service.upstream_cx_overflow.count.sum, asg={{destination_service}})
                    regexes:
                      - regex: "host='([^']+)'"
                        replacement: "host: $1"
              - title: {{destination_service}} request overflow
                datasource: wavefront
                targets:
                  - target: ts($environment.infra.aws.ec2.instance.envoy.cluster.local_service.upstream_rq_pending_overflow.count.sum, asg={{destination_service}})
                    regexes:
                      - regex: "host='([^']+)'"
                        replacement: "host: $1"
              - title: {{originating_service}} to {{destination_service}} retry overflow
                datasource: wavefront
                targets:
                  - target: ts($environment.infra.aws.ec2.asg.envoy.cluster.{{destination_service}}.upstream_rq_retry_overflow.count.sum, asg={{originating_service}})
                    name: retry overflow
              - title: {{originating_service}} to {{destination_service}} connection overflow
                datasource: wavefront
                targets:
                  - target: ts($environment.infra.aws.ec2.asg.envoy.cluster.{{destination_service}}.upstream_cx_overflow.count.sum, asg={{originating_service}})
                    name: connection overflow
              - title: {{originating_service}} to {{destination_service}} request overflow
                datasource: wavefront
                targets:
                  - target: ts($environment.infra.aws.ec2.asg.envoy.cluster.{{destination_service}}.upstream_rq_pending_overflow.count.sum, asg={{originating_service}})
                    name: request overflow
{% endmacro %}

{% macro upstream_http_success_rate_alarm_panel(originating_service, destination_service, success_percentage=99, alarm_minutes=2, alarm_target=None) %}
              - title: {{ originating_service }}->{{ destination_service }} HTTP success rate
                datasource: wavefront
                alarms:
                  - name: HTTP Success rate for {{ originating_service }}->{{ destination_service }} below threshold
                    query: 100 * (1 - (align(1m, (( default(4w, 0, rawsum(ts($environment.infra.aws.ec2.asg.envoy.cluster.{{ destination_service }}.upstream_rq_5xx.count.rate, asg={{ originating_service }} and region=iad and window=60)) ))))/default(4w, 0, rawsum(ts($environment.infra.aws.ec2.asg.envoy.cluster.{{ destination_service }}.upstream_rq_total.count.rate, asg={{ originating_service }} and region=iad and window=60)))))
                    condition: $query < {{ success_percentage }}
                    minutes: {{ alarm_minutes}}
                    {% if alarm_target %}
                    service: {{ alarm_target }}
                    {% endif %}
                    tags:
                      lightstep_target_type: error
{% endmacro %}

{% macro upstream_grpc_success_rate_alarm_panel(originating_service, destination_service, success_percentage=99, alarm_minutes=2, alarm_target=None) %}
              - title: {{ originating_service }}->{{ destination_service }} GRPC success rate
                datasource: wavefront
                alarms:
                  - name: GRPC Success rate for {{ originating_service }}->{{ destination_service }} below threshold
                    query: 100*(rawsum(taggify(align(1m,default(0, ts($environment.infra.aws.ec2.asg.envoy.cluster.{{ destination_service }}.grpc.pb.lyft.*.success.count.sum, asg={{ originating_service }} and window=60))), metric, methodname, 13), methodname)) / (rawsum(taggify(align(1m,default(0, ts($environment.infra.aws.ec2.asg.envoy.cluster.{{ destination_service }}.grpc.pb.lyft.*.total.count.sum, asg={{ originating_service }} and window=60))), metric, methodname, 13), methodname))
                    condition: $query < {{ success_percentage }}
                    minutes: {{ alarm_minutes}}
                    {% if alarm_target %}
                    service: {{ alarm_target }}
                    {% endif %}
                    tags:
                      lightstep_target_type: error
{% endmacro %}

{% macro downstream_requests(destination_service) %}
              - title: Total requests per second
                datasource: wavefront
                span: 3
                targets:
                  - target: ts($environment.infra.aws.ec2.asg.envoy.cluster.{{destination_service}}.upstream_rq_total.count.rate, window=60)
                    regexes:
                      - regex: "asg='([^']+)'"
                        replacement: $1
              - title: Total 5xx requests per second
                datasource: wavefront
                span: 3
                targets:
                  - target: ts($environment.infra.aws.ec2.asg.envoy.cluster.{{destination_service}}.upstream_rq_5xx.count.rate, window=60)
                    regexes:
                      - regex: "asg='([^']+)'"
                        replacement: $1
              - title: Total request errors per second
                datasource: wavefront
                span: 3
                targets:
                  - target: ts($environment.infra.aws.ec2.asg.envoy.cluster.{{destination_service}}.upstream_cx_connect_timeout.count.rate, window=60)
                    regexes:
                      - regex: "asg='([^']+)'"
                        replacement: connect timeout $1
                  - target: ts($environment.infra.aws.ec2.asg.envoy.cluster.{{destination_service}}.upstream_rq_pending_failure_eject.count.rate, window=60)
                    regexes:
                      - regex: "asg='([^']+)'"
                        replacement: pending failure ejection $1
                  - target: ts($environment.infra.aws.ec2.asg.envoy.cluster.{{destination_service}}.upstream_rq_pending_overflow.count.rate, window=60)
                    regexes:
                      - regex: "asg='([^']+)'"
                        replacement: pending overflow $1
                  - target: ts($environment.infra.aws.ec2.asg.envoy.cluster.{{destination_service}}.upstream_rq_timeout.count.rate, window=60)
                    regexes:
                      - regex: "asg='([^']+)'"
                        replacement: request timeout $1
                  - target: ts($environment.infra.aws.ec2.asg.envoy.cluster.{{destination_service}}.upstream_rq_per_try_timeout.count.rate, window=60)
                    regexes:
                      - regex: "asg='([^']+)'"
                        replacement: per try request timeout $1
                  - target: ts($environment.infra.aws.ec2.asg.envoy.cluster.{{destination_service}}.upstream_rq_rx_reset.count.rate, window=60)
                    regexes:
                      - regex: "asg='([^']+)'"
                        replacement: request reset $1
                  - target: ts($environment.infra.aws.ec2.asg.envoy.cluster.{{destination_service}}.upstream_cx_destroy_local_with_active_rq.count.rate, window=60)
                    regexes:
                      - regex: "asg='([^']+)'"
                        replacement: destroy initialized from $1
                  - target: ts($environment.infra.aws.ec2.asg.envoy.cluster.{{destination_service}}.upstream_cx_destroy_remote_with_active_rq.count.rate, window=60)
                    regexes:
                      - regex: "asg='([^']+)'"
                        replacement: destroy initialized from destination service seen in $1
                  - target: ts($environment.infra.aws.ec2.asg.envoy.cluster.{{destination_service}}.upstream_rq_maintenance_mode.count.rate, window=60)
                    regexes:
                      - regex: "asg='([^']+)'"
                        replacement: request failed maintenance mode $1
              - title: Total request retries per second
                datasource: wavefront
                span: 3
                targets:
                  - target: ts($environment.infra.aws.ec2.asg.envoy.cluster.{{destination_service}}.upstream_rq_retry.count.rate, window=60)
                    regexes:
                      - regex: "asg='([^']+)'"
                        replacement: request retry $1
                  - target: ts($environment.infra.aws.ec2.asg.envoy.cluster.{{destination_service}}.upstream_rq_retry_success.count.rate, window=60)
                    regexes:
                      - regex: "asg='([^']+)'"
                        replacement: request retry success $1
                  - target: ts($environment.infra.aws.ec2.asg.envoy.cluster.{{destination_service}}.upstream_rq_retry_overflow.count.rate, window=60)
                    regexes:
                      - regex: "asg='([^']+)'"
                        replacement: request retry overflow $1
{% endmacro%}
