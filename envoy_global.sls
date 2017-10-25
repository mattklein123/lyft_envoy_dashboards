{% from "macros/envoy_stats.sls" import envoy_gauge_divisor %}

Ensure LightStep SR is high low urgency alert:
  wavefront_alerts.present:
    - name: LightStep SR is low
      condition: $display < 97
      displayExpression: rawsum(default(0, ts(production.infra.aws.ec2.asg.envoy.cluster.lightstep_saas.grpc.lightstep.collector.CollectorService.Report.success.count.sum))) / rawsum(ts(production.infra.aws.ec2.asg.envoy.cluster.lightstep_saas.grpc.lightstep.collector.CollectorService.Report.total.count.sum)) * 100
      service: lightstep-low-urgency
      minutes: 3

{% for db_name, canary in
  [('Envoy-Global', False),
   ('Envoy-Global-Canary', True)] %}

Ensure {{db_name}} dashboard is managed:
  lyft_dashboard.present:
    - name: {{db_name}}
    - base_rows_from_pillar:
      - 'grafana_rows:title'
    - base_panels_from_pillar:
      - 'grafana_panels:no_fill'
      - 'grafana_panels:hide_legend'
      - 'grafana_panels:thin'
      - 'grafana_panels:4span'
    - pagerduty_target: envoy
    - dashboard:
        refresh: 1m
        tags:
          - managed
        annotation_tags:
          - "opsbase-deploy-production"
          - "runtime-deploy-production"
        time:
          from: "now-6h"
          to: "now-2m"
        rows:
          - title: Dashboard README
            height: 50
            showTitle: True
            panels:
              - title:
                content: This dashboard represents global health state of all services. Explanation of these stats can be found [at this link](https://github.com/lyft/envoy-private/blob/master/docs/stats.md#envoy-global-stats)
                type: text
          - title: TOP LEVEL ALL ENVOYS
            panels:
              - title: RPS
                datasource: wavefront
                targets:
                  - target: 'rawsum(ts(production.infra.aws.ec2.asg.envoy.http.*.downstream_rq_total.count.rate))'
                    name: 'Global RPS'
                  - target: 'rawsum(ts(production.infra.aws.ec2.asg.envoy.cluster.*.health_check.attempt.count.rate))'
                    name: 'Global HC RPS'
                  - target: 'rawsum(ts(production.infra.aws.ec2.asg.envoy.http.*.rq_total.count.rate))'
                    name: 'Global Routed RPS'
                  - target: 'rawsum(ts(production.infra.aws.ec2.asg.envoy.cluster.lightstep_saas.upstream_rq_total.count.rate))'
                    name: 'Global Tracing RPS'
                  {% if canary %}
                  - target: 'rawsum(ts(production.infra.aws.ec2.asg.envoy.http.*.downstream_rq_total.instance.count.rate, canary=true))'
                    name: 'Canary Global RPS'
                  - target: 'rawsum(ts(production.infra.aws.ec2.asg.envoy.cluster.*.health_check.attempt.instance.count.rate, canary=true))'
                    name: 'Canary Global HC RPS'
                  - target: 'rawsum(ts(production.infra.aws.ec2.asg.envoy.http.*.rq_total.count.instance.rate, canary=true))'
                    name: 'Canary Global Routed RPS'
                  - target: 'rawsum(ts(production.infra.aws.ec2.asg.envoy.cluster.lightstep_saas.upstream_rq_total.instance.count.rate, canary=true))'
                    name: 'Canary Global Tracing RPS'
                  {% endif %}
              - title: CPS
                datasource: wavefront
                targets:
                  - target: 'rawsum(ts(production.infra.aws.ec2.asg.envoy.http.*.downstream_cx_total.count.rate))'
                    name: 'Global CPS'
                  {% if canary %}
                  - target: 'rawsum(ts(production.infra.aws.ec2.asg.envoy.http.*.downstream_cx_total.instance.count.rate, canary=true))'
                    name: 'Canary Global CPS'
                  {% endif %}
              - title: Success Rate (non-5xx responses)
                datasource: wavefront
                targets:
                  - target: '(1 - (rawsum(ts(production.infra.aws.ec2.asg.envoy.http.*.downstream_rq_5xx.count.sum)) / rawsum(ts(production.infra.aws.ec2.asg.envoy.http.*.downstream_rq_*xx.count.sum)))) * 100'
                    name: 'SR'
                  {% if canary %}
                  - target: '(1 - (rawsum(ts(production.infra.aws.ec2.asg.envoy.http.*.downstream_rq_5xx.instance.count.sum, canary=true)) / rawsum(ts(production.infra.aws.ec2.asg.envoy.http.*.downstream_rq_*xx.instance.count.sum, canary=true)))) * 100'
                    name: 'Canary SR'
                  {% endif %}
              - title: Connections
                datasource: wavefront
                targets:
                  - target: 'rawsum(ts(production.infra.aws.ec2.asg.envoy.http.*.downstream_cx_active.gauge.sum)) / {{ envoy_gauge_divisor }}'
                    name: 'Global Connections'
                  - target: 'rawsum(ts(production.infra.aws.ec2.asg.envoy.server.parent_connections.gauge.sum)) / {{ envoy_gauge_divisor }}'
                    name: 'Global Parent Connections'
                  {% if canary %}
                  - target: 'rawsum(ts(production.infra.aws.ec2.asg.envoy.http.*.downstream_cx_active.instance.gauge.sum, canary=true)) / {{ envoy_gauge_divisor }}'
                    name: 'Canary Global Connections'
                  - target: 'rawsum(ts(production.infra.aws.ec2.asg.envoy.server.parent_connections.instance.gauge.sum, canary=true)) / {{ envoy_gauge_divisor }}'
                    name: 'Canary Global Parent Connections'
                  {% endif %}
              - title: Deployed Version
                datasource: wavefront
                targets:
                  - target: 'ts(production.infra.aws.ec2.asg.envoy.server.version.gauge.min)'
                  - target: 'ts(production.infra.aws.ec2.asg.envoy.server.version.gauge.max)'
              - title: Upstream failures
                datasource: wavefront
                targets:
                  - target: 'rawsum(ts(production.infra.aws.ec2.asg.envoy.cluster.*.upstream_rq_pending_failure_eject.count.rate))'
                    name: 'Pending Failure Ejection'
                  - target: 'rawsum(ts(production.infra.aws.ec2.asg.envoy.cluster.*.upstream_rq_pending_overflow.count.rate))'
                    name: 'Pending Overflow'
                  - target: 'rawsum(ts(production.infra.aws.ec2.asg.envoy.cluster.*.upstream_cx_connect_timeout.count.rate))'
                    name: 'Connect Timeout'
                  - target: 'rawsum(ts(production.infra.aws.ec2.asg.envoy.cluster.*.upstream_rq_timeout.count.rate))'
                    name: 'Request Timeout'
                  {% if canary %}
                  - target: 'rawsum(ts(production.infra.aws.ec2.asg.envoy.cluster.*.upstream_rq_pending_failure_eject.instance.count.rate, canary=true))'
                    name: 'Canary Pending Failure Ejection'
                  - target: 'rawsum(ts(production.infra.aws.ec2.asg.envoy.cluster.*.upstream_rq_pending_overflow.instance.count.rate, canary=true))'
                    name: 'Canary Pending Overflow'
                  - target: 'rawsum(ts(production.infra.aws.ec2.asg.envoy.cluster.*.upstream_cx_connect_timeout.instance.count.rate, canary=true))'
                    name: 'Canary Connect Timeout'
                  - target: 'rawsum(ts(production.infra.aws.ec2.asg.envoy.cluster.*.upstream_rq_timeout.instance.count.rate, canary=true))'
                    name: 'Canary Request Timeout'
                  {% endif %}
              - title: Upstream Retries
                datasource: wavefront
                targets:
                  - target: 'rawsum(ts(production.infra.aws.ec2.asg.envoy.cluster.*.upstream_rq_retry.count.rate))'
                    name: 'Retry'
                  - target: 'rawsum(ts(production.infra.aws.ec2.asg.envoy.cluster.*.upstream_rq_retry_success.count.rate))'
                    name: 'Retry Success'
                  - target: 'rawsum(ts(production.infra.aws.ec2.asg.envoy.cluster.*.upstream_rq_retry_overflow.count.rate))'
                    name: 'Retry Overflow'
                  {% if canary %}
                  - target: 'rawsum(ts(production.infra.aws.ec2.asg.envoy.cluster.*.upstream_rq_retry.instance.count.rate, canary=true))'
                    name: 'Canary Retry'
                  - target: 'rawsum(ts(production.infra.aws.ec2.asg.envoy.cluster.*.upstream_rq_retry_success.instance.count.rate, canary=true))'
                    name: 'Canary Retry Success'
                  - target: 'rawsum(ts(production.infra.aws.ec2.asg.envoy.cluster.*.upstream_rq_retry_overflow.count.rate, canary=true))'
                    name: 'Canary Retry Overflow'
                  {% endif %}
              - title: Outlier Detection
                datasource: wavefront
                targets:
                  - target: 'rawsum(ts(production.infra.aws.ec2.asg.envoy.cluster.*.outlier_detection.ejections_total.count.sum))'
                    name: 'Total ejections'
                  - target: 'rawsum(ts(production.infra.aws.ec2.asg.envoy.cluster.*.outlier_detection.ejections_overflow.count.sum))'
                    name: 'Total ejection overflows'
                  {% if canary %}
                  - target: 'rawsum(ts(production.infra.aws.ec2.asg.envoy.cluster.*.outlier_detection.ejections_total.count.sum, canary=true))'
                    name: 'Canary Total ejections'
                  - target: 'rawsum(ts(production.infra.aws.ec2.asg.envoy.cluster.*.outlier_detection.ejections_overflow.count.sum, canary=true))'
                    name: 'Canary Total ejection overflows'
                  {% endif %}
          - title: Cross Zone Traffic
            collapse: True
            panels:
              - title: RPS
                datasource: wavefront
                targets:
                  - target: 'rawsum(removeSeries(taggify(taggify(taggify(ts(production.infra.aws.ec2.asg.envoy.cluster.*.zone.*.upstream_rq_*xx.count.rate), metric, cluster, 7), metric, from_zone, 9), metric, to_zone, 10), cluster=jenkins), from_zone, to_zone)'
                    regexes:
                      - regex: "from_zone='([^']+)'.*to_zone='([^']+)'"
                        replacement: "$1.$2"
                  {% if canary %}
                  - target: 'rawsum(removeSeries(taggify(taggify(taggify(ts(production.infra.aws.ec2.asg.envoy.cluster.*.zone.*.upstream_rq_*xx.instance.count.rate, canary=true), metric, cluster, 7), metric, from_zone, 9), metric, to_zone, 10), cluster=jenkins), from_zone, to_zone)'
                    regexes:
                      - regex: "from_zone='([^']+)'.*to_zone='([^']+)'"
                        replacement: "Canary $1.$2"
                  {% endif %}
              - title: P50 LATENCY
                datasource: wavefront
                targets:
                  - target: 'rawavg(removeSeries(taggify(taggify(taggify(ts(production.infra.aws.ec2.asg.envoy.cluster.*.zone.*.upstream_rq_time.timer.p50), metric, cluster, 7), metric, from_zone, 9), metric, to_zone, 10), cluster=jenkins), from_zone, to_zone)'
                    regexes:
                      - regex: "from_zone='([^']+)'.*to_zone='([^']+)'"
                        replacement: "$1.$2.p50"
                  {% if canary %}
                  - target: 'rawavg(removeSeries(taggify(taggify(taggify(ts(production.infra.aws.ec2.asg.envoy.cluster.*.zone.*.upstream_rq_time.instance.timer.p50, canary=true), metric, cluster, 7), metric, from_zone, 9), metric, to_zone, 10), cluster=jenkins), from_zone, to_zone)'
                    regexes:
                      - regex: "from_zone='([^']+)'.*to_zone='([^']+)'"
                        replacement: "Canary $1.$2.p50"
                  {% endif %}
              - title: P95 LATENCY
                datasource: wavefront
                targets:
                  - target: 'rawavg(removeSeries(taggify(taggify(taggify(ts(production.infra.aws.ec2.asg.envoy.cluster.*.zone.*.upstream_rq_time.timer.p95), metric, cluster, 7), metric, from_zone, 9), metric, to_zone, 10), cluster=jenkins), from_zone, to_zone)'
                    regexes:
                      - regex: "from_zone='([^']+)'.*to_zone='([^']+)'"
                        replacement: "$1.$2.p95"
                  {% if canary %}
                  - target: 'rawavg(removeSeries(taggify(taggify(taggify(ts(production.infra.aws.ec2.asg.envoy.cluster.*.zone.*.upstream_rq_time.instance.timer.p95, canary=true), metric, cluster, 7), metric, from_zone, 9), metric, to_zone, 10), cluster=jenkins), from_zone, to_zone)'
                    regexes:
                      - regex: "from_zone='([^']+)'.*to_zone='([^']+)'"
                        replacement: "Canary $1.$2.p95"
                  {% endif %}
                alarms:
                  - name: "Heightened P95 Latency"
                    query: 'rawavg(removeSeries(taggify(taggify(taggify(ts(production.infra.aws.ec2.asg.envoy.cluster.*.zone.*.upstream_rq_time.timer.p95), metric, cluster, 7), metric, from_zone, 9), metric, to_zone, 10), cluster=jenkins), from_zone, to_zone)'
                    condition: '(($query - mmedian(200m, $query))/(mpercentile(200m, 75, $query) - mpercentile(200m, 25, $query))) > 3'
                    hide: true
                    minutes: 10
              - title: P99 LATENCY
                datasource: wavefront
                targets:
                  - target: 'rawavg(removeSeries(taggify(taggify(taggify(ts(production.infra.aws.ec2.asg.envoy.cluster.*.zone.*.upstream_rq_time.timer.p99), metric, cluster, 7), metric, from_zone, 9), metric, to_zone, 10), cluster=jenkins), from_zone, to_zone)'
                    regexes:
                      - regex: "from_zone='([^']+)'.*to_zone='([^']+)'"
                        replacement: "$1.$2.p99"
                  {% if canary %}
                  - target: 'rawavg(removeSeries(taggify(taggify(taggify(ts(production.infra.aws.ec2.asg.envoy.cluster.*.zone.*.upstream_rq_time.instance.timer.p99, canary=true), metric, cluster, 7), metric, from_zone, 9), metric, to_zone, 10), cluster=jenkins), from_zone, to_zone)'
                    regexes:
                      - regex: "from_zone='([^']+)'.*to_zone='([^']+)'"
                        replacement: "Canary $1.$2.p99"
                  {% endif %}
          - title: RATELIMIT
            collapse: True
            panels:
              - title: TCP limiter per second
                datasource: wavefront
                targets:
                  - target: 'rawsum(ts(production.infra.aws.ec2.asg.envoy.ratelimit.*.over_limit.count.rate))'
                    name: 'Global Over Limit'
                  - target: 'rawsum(ts(production.infra.aws.ec2.asg.envoy.ratelimit.*.ok.count.rate))'
                    name: 'Global OK'
                  - target: 'rawsum(ts(production.infra.aws.ec2.asg.envoy.ratelimit.*.error.count.rate))'
                    name: 'Global Error'
                  {% if canary %}
                  - target: 'rawsum(ts(production.infra.aws.ec2.asg.envoy.ratelimit.*.over_limit.instance.count.rate, canary=true))'
                    name: Canary Global RPS
                  - target: 'rawsum(ts(production.infra.aws.ec2.asg.envoy.ratelimit.*.ok.instance.count.rate, canary=true))'
                    name: 'Canary Global OK'
                  - target: 'rawsum(ts(production.infra.aws.ec2.asg.envoy.ratelimit.*.error.instance.count.rate, canary=true))'
                    name: 'Canary Global Error'
                  {% endif%}
              - title: HTTP limiter per second
                datasource: wavefront
                targets:
                  - target: 'rawsum(ts(production.infra.aws.ec2.asg.envoy.cluster.*.ratelimit.over_limit.count.rate))'
                    name: 'Global Over Limit'
                  - target: 'rawsum(ts(production.infra.aws.ec2.asg.envoy.cluster.*.ratelimit.ok.count.rate))'
                    name: 'Global OK'
                  - target: 'rawsum(ts(production.infra.aws.ec2.asg.envoy.cluster.*.ratelimit.error.count.rate))'
                    name: 'Global Error'
                  {% if canary %}
                  - target: 'rawsum(ts(production.infra.aws.ec2.asg.envoy.cluster.*.ratelimit.over_limit.instance.count.rate, canary=true))'
                    name: Canary Global RPS
                  - target: 'rawsum(ts(production.infra.aws.ec2.asg.envoy.cluster.*.ratelimit.ok.instance.count.rate, canary=true))'
                    name: 'Canary Global OK'
                  - target: 'rawsum(ts(production.infra.aws.ec2.asg.envoy.cluster.*.ratelimit.error.instance.count.rate, canary=true))'
                    name: 'Canary Global Error'
                  {% endif%}
          - title: LIGHTSTEP GLOBAL
            collapse: True
            panels:
              - title: RPS
                datasource: wavefront
                targets:
                  - target: 'rawsum(ts(production.infra.aws.ec2.asg.envoy.cluster.lightstep_saas.upstream_rq_total.count.rate))'
                    name: 'Global RPS'
                  {% if canary %}
                  - target: 'rawsum(ts(production.infra.aws.ec2.asg.envoy.cluster.lightstep_saas.upstream_rq_total.instance.count.rate, canary=true))'
                    name: Canary Global RPS
                  {% endif%}
              - title: Spans Per Second
                datasource: wavefront
                targets:
                  - target: 'rawsum(ts(production.infra.aws.ec2.asg.envoy.tracing.lightstep.spans_sent.count.rate))'
                    name: 'Global Spans Per Second'
                  {% if canary %}
                  - target: 'rawsum(ts(production.infra.aws.ec2.asg.envoy.tracing.lightstep.spans_sent.instance.count.rate, canary=true))'
                    name: 'Canary Global Spans Per Second'
                  {% endif%}
              - title: Success Rate (gRPC requests)
                datasource: wavefront
                targets:
                  - target: '(1 - (rawsum(default(0, ts(production.infra.aws.ec2.asg.envoy.cluster.lightstep_saas.grpc.lightstep.collector.CollectorService.Report.failure.count.sum))) / rawsum(ts(production.infra.aws.ec2.asg.envoy.cluster.lightstep_saas.grpc.lightstep.collector.CollectorService.Report.total.count.sum)))) * 100'
                    name: 'SR'
                  {% if canary %}
                  - target: '(1 - (rawsum(default(0, ts(production.infra.aws.ec2.asg.envoy.cluster.lightstep_saas.grpc.lightstep.collector.CollectorService.Report.failure.instance.count.sum, canary=true))) / rawsum(ts(production.infra.aws.ec2.asg.envoy.cluster.lightstep_saas.grpc.lightstep.collector.CollectorService.Report.total.instance.count.sum, canary=true)))) * 100'
                    name: 'Canary SR'
                  {% endif %}
              - title: LightStep failures
                datasource: wavefront
                targets:
                  - target: 'rawsum(ts(production.infra.aws.ec2.asg.envoy.cluster.lightstep_saas.upstream_rq_pending_failure_eject.count.rate))'
                    name: 'Pending Failure Ejection'
                  - target: 'rawsum(ts(production.infra.aws.ec2.asg.envoy.cluster.lightstep_saas.upstream_rq_pending_overflow.count.rate))'
                    name: 'Pending Overflow'
                  - target: 'rawsum(ts(production.infra.aws.ec2.asg.envoy.cluster.lightstep_saas.upstream_cx_connect_timeout.count.rate))'
                    name: 'Connect Timeout'
                  - target: 'rawsum(ts(production.infra.aws.ec2.asg.envoy.cluster.lightstep_saas.upstream_rq_timeout.count.rate))'
                    name: 'Request Timeout'
                  {% if canary %}
                  - target: 'rawsum(ts(production.infra.aws.ec2.asg.envoy.cluster.lightstep_saas.upstream_rq_pending_failure_eject.instance.count.rate, canary=true))'
                    name: 'Canary Pending Failure Ejection'
                  - target: 'rawsum(ts(production.infra.aws.ec2.asg.envoy.cluster.lightstep_saas.upstream_rq_pending_overflow.instance.count.rate, canary=true))'
                    name: 'Canary Pending Overflow'
                  - target: 'rawsum(ts(production.infra.aws.ec2.asg.envoy.cluster.lightstep_saas.upstream_cx_connect_timeout.instance.count.rate, canary=true))'
                    name: 'Canary Connect Timeout'
                  - target: 'rawsum(ts(production.infra.aws.ec2.asg.envoy.cluster.lightstep_saas.upstream_rq_timeout.instance.count.rate, canary=true))'
                    name: 'Canary Request Timeout'
                  {% endif %}
          - title: CUSTOM CONFIG
            collapse: True
            panels:
              - title: Custom Config Attemps
                datasource: wavefront
                targets:
                  - target: 'ts(production.app.configgen.custom_config.create_attempt.count.count)'
              - title: Custom Config Failures
                datasource: wavefront
                alarms:
                  - name: "Custom Config Failure"
                    query: 'mcount(5m, ts(production.app.configgen.custom_config.create_failure.count.count))'
                    condition: $query > 0
                    minutes: 2
          - title: ENVOY SERVER CRASHES
            collapse: True
            panels:
              - title: Envoy Server Crashes
                datasource: wavefront
                alarms:
                  - name: "Envoy Server Crashes"
                    query: 'msum(10m, ts(production.infra.aws.ec2.asg.envoy.server.crashes.count.sum))'
                    condition: $query > 5
                    minutes: 2
{% endfor %}
