{% from "macros/front_envoy_core_stats.sls" import top_level_all_hosts %}
{% from "macros/front_envoy_core_stats.sls" import per_host %}
{% from "macros/front_envoy_core_stats.sls" import system_health %}
{% from "macros/envoymanager.sls" import envoymanager_front_envoy_rds %}
{% from "macros/sla_per_service/machine_stats.sls" import sla_per_service_machine_stats %}

{% set info = salt['pillar.get']('envoy', pillar['envoy'], True) %}

Ensure days until first SSL cert expires high urgency alert:
  wavefront_alerts.present:
    - name: Envoy days until first SSL cert expires high urgency
      condition: $display < 14
      displayExpression: ts(production.infra.aws.ec2.asg.envoy.server.days_until_first_cert_expiring.instance.gauge.mean, asg=envoy)
      service: envoy-security
      minutes: 3

Ensure days until first SSL cert expires low urgency alert:
  wavefront_alerts.present:
    - name: Envoy days until first SSL cert expires low urgency
      condition: $display < 6
      displayExpression: ts(production.infra.aws.ec2.asg.envoy.server.days_until_first_cert_expiring.instance.gauge.mean, asg=envoy)
      service: networking-low-urgency
      minutes: 3

Ensure polling rate filter active alert:
  wavefront_alerts.present:
    - name: Envoy polling rate filter active
      runbook: https://github.com/lyft/envoy-private/blob/master/docs/polling_rate.md#what-to-do-if-you-get-paged
      condition: $display > 0
      displayExpression: ts(production.infra.aws.ec2.asg.envoy.listener*polling_rate*.current_state.gauge.max, asg=envoy)
      service: envoy
      minutes: 1

{% for cluster, canary in
  [('envoy', False),
   ('envoy-canary', True)] %}

{% set regions = ['iad', 'sfo'] %}

{% macro upstream_row(region, cluster) %}
          - title: {{region}} PER HOST {{cluster}} UPSTREAM
            collapse: True
            panels:
              - title: CPS / RPS
                datasource: wavefront
                targets:
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.cluster.{{cluster}}.upstream_cx_total.instance.count.rate, region={{region}} and asg=envoy))'
                    name: 'CPS'
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.cluster.{{cluster}}.upstream_rq_total.instance.count.rate, region={{region}} and asg=envoy))'
                    name: 'RPS'
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.cluster.{{cluster}}.upstream_rq_pending_total.instance.count.rate, region={{region}} and asg=envoy))'
                    name: 'Pending'
                {% if canary %}
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.cluster.{{cluster}}.upstream_cx_total.instance.count.rate, region={{region}} and asg=envoy and canary=true))'
                    name: 'CPS Canary'
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.cluster.{{cluster}}.upstream_rq_total.instance.count.rate, region={{region}} and asg=envoy and canary=true))'
                    name: 'RPS Canary'
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.cluster.{{cluster}}.upstream_rq_pending_total.instance.count.rate, region={{region}} and asg=envoy and canary=true))'
                    name: 'Pending Canary'
                {% endif %}
              - title: Total Connections / Requests
                datasource: wavefront
                targets:
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.cluster.{{cluster}}.upstream_cx_active.instance.gauge.mean, region={{region}} and asg=envoy))'
                    name: 'Connections'
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.cluster.{{cluster}}.upstream_rq_active.instance.gauge.mean, region={{region}} and asg=envoy))'
                    name: 'Requests'
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.cluster.{{cluster}}.upstream_rq_pending_active.gauge.mean, region={{region}} and asg=envoy))'
                    name: 'Pending'
                {% if canary %}
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.cluster.{{cluster}}.upstream_cx_active.instance.gauge.mean, region={{region}} and asg=envoy and canary=true))'
                    name: 'Connections Canary'
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.cluster.{{cluster}}.upstream_rq_active.instance.gauge.mean, region={{region}} and asg=envoy and canary=true))'
                    name: 'Requests Canary'
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.cluster.{{cluster}}.upstream_rq_pending_active.gauge.mean, region={{region}} and asg=envoy and canary=true))'
                    name: 'Pending Canary'
                {% endif %}
              - title: Connection Length
                datasource: wavefront
                targets:
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.cluster.{{cluster}}.upstream_cx_length_ms.instance.timer.p50, region={{region}} and asg=envoy))'
                    name: 'P50'
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.cluster.{{cluster}}.upstream_cx_length_ms.instance.timer.p95, region={{region}} and asg=envoy))'
                    name: 'P95'
                {% if canary %}
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.cluster.{{cluster}}.upstream_cx_length_ms.instance.timer.p50, region={{region}} and asg=envoy and canary=true))'
                    name: 'P50 Canary'
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.cluster.{{cluster}}.upstream_cx_length_ms.instance.timer.p95, region={{region}} and asg=envoy and canary=true))'
                    name: 'P95 Canary'
                {% endif %}
                y_formats:
                  - ms
                  - short
              - title: Upstream Response Time
                datasource: wavefront
                targets:
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.cluster.{{cluster}}.upstream_rq_time.instance.timer.p50, region={{region}} and asg=envoy))'
                    name: 'P50'
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.cluster.{{cluster}}.upstream_rq_time.instance.timer.p95, region={{region}} and asg=envoy))'
                    name: 'P95'
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.cluster.{{cluster}}.upstream_rq_time.instance.timer.p99, region={{region}} and asg=envoy))'
                    name: 'P99'
                {% if canary %}
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.cluster.{{cluster}}.upstream_rq_time.instance.timer.p50, region={{region}} and asg=envoy and canary=true))'
                    name: 'P50 Canary'
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.cluster.{{cluster}}.upstream_rq_time.instance.timer.p95, region={{region}} and asg=envoy and canary=true))'
                    name: 'P95 Canary'
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.cluster.{{cluster}}.upstream_rq_time.instance.timer.p99, region={{region}} and asg=envoy and canary=true))'
                    name: 'P99 Canary'
                {% endif %}
                y_formats:
                  - ms
                  - short
              - title: Upstream Errors
                datasource: wavefront
                targets:
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.cluster.{{cluster}}.upstream_cx_connect_timeout.instance.count.rate, region={{region}} and asg=envoy))'
                    name: 'Connect Timeout'
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.cluster.{{cluster}}.upstream_rq_pending_failure_eject.instance.count.rate, region={{region}} and asg=envoy))'
                    name: 'Pending Failure Ejection'
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.cluster.{{cluster}}.upstream_rq_pending_overflow.instance.count.rate, region={{region}} and asg=envoy))'
                    name: 'Pending Overflow'
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.cluster.{{cluster}}.upstream_rq_timeout.instance.count.rate, region={{region}} and asg=envoy))'
                    name: 'Request Timeout'
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.cluster.{{cluster}}.upstream_rq_rx_reset.instance.count.rate, region={{region}} and asg=envoy))'
                    name: 'Request Rx Reset'
                {% if canary %}
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.cluster.{{cluster}}.upstream_cx_connect_timeout.instance.count.rate, region={{region}} and asg=envoy and canary=true))'
                    name: 'Connect Timeout Canary'
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.cluster.{{cluster}}.upstream_rq_pending_failure_eject.instance.count.rate, region={{region}} and asg=envoy and canary=true))'
                    name: 'Pending Failure Ejection Canary'
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.cluster.{{cluster}}.upstream_rq_pending_overflow.instance.count.rate, region={{region}} and asg=envoy and canary=true))'
                    name: 'Pending Overflow Canary'
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.cluster.{{cluster}}.upstream_rq_timeout.instance.count.rate, region={{region}} and asg=envoy and canary=true))'
                    name: 'Request Timeout Canary'
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.cluster.{{cluster}}.upstream_rq_rx_reset.instance.count.rate, region={{region}} and asg=envoy and canary=true))'
                    name: 'Request Rx Reset Canary'
                {% endif %}
              - title: Cluster Membership
                datasource: wavefront
                targets:
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.cluster.{{cluster}}.membership_change.instance.count.sum, region={{region}} and asg=envoy))'
                    name: 'Membership Changes'
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.cluster.{{cluster}}.membership_total.instance.gauge.mean, region={{region}} and asg=envoy))'
                    name: 'Membership Total'
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.cluster.{{cluster}}.health_check.healthy.instance.gauge.mean, region={{region}} and asg=envoy))'
                    name: 'Healthy Total'
                {% if canary %}
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.cluster.{{cluster}}.membership_change.instance.count.sum, region={{region}} and asg=envoy and canary=true))'
                    name: 'Membership Changes Canary'
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.cluster.{{cluster}}.membership_total.instance.gauge.mean, region={{region}} and asg=envoy and canary=true))'
                    name: 'Membership Total Canary'
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.cluster.{{cluster}}.health_check.healthy.instance.gauge.mean, region={{region}} and asg=envoy and canary=true))'
                    name: 'Healthy Total Canary'
                {% endif %}
              - title: 5xx Per Second
                datasource: wavefront
                targets:
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.cluster.{{cluster}}.upstream_rq_5xx.instance.count.rate, region={{region}} and asg=envoy))'
                    name: '5xx Count'
                {% if canary %}
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.cluster.{{cluster}}.upstream_rq_5xx.instance.count.rate, region={{region}} and asg=envoy and canary=true))'
                    name: '5xx Count Canary'
                {% endif %}
{% endmacro %}

Ensure {{cluster}} dashboard is managed:
  lyft_dashboard.present:
    - name: {{cluster}}
    - base_rows_from_pillar:
      - 'grafana_rows:title'
    - base_panels_from_pillar:
      - 'grafana_panels:no_fill'
      - 'grafana_panels:hide_legend'
      - 'grafana_panels:thin'
    - pagerduty_target: envoy
    - dashboard:
        refresh: 1m
        tags:
          - managed
        time:
          from: "now-6h"
          to: "now-2m"
        rows:
          {{ top_level_all_hosts('envoy', regions, canary, 'envoy', 97, 8) }}
          {{ per_host('envoy', regions, canary, 'envoy', 750, 4000, 60000, 4000) }}
          {{ upstream_row('sfo', 'backhaul') }}
          - title: IAD AUTHENTICATION PER HOST
            collapse: True
            panels:
              - title: lyft token auth status
                datasource: wavefront
                targets:
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.http.router.legacy_lyft_token.ok.instance.count.rate, region=iad and asg=envoy))'
                    name: 'Success'
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.http.router.legacy_lyft_token.error.instance.count.rate, region=iad and asg=envoy))'
                    name: 'Failure'
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.http.router.legacy_lyft_token.unauthorized.instance.count.rate, region=iad and asg=envoy))'
                    name: 'Denied'
                {% if canary %}
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.http.router.legacy_lyft_token.ok.instance.count.rate, region=iad and asg=envoy and canary=true))'
                    name: 'Success Canary'
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.http.router.legacy_lyft_token.error.instance.count.rate, region=iad and asg=envoy and canary=true))'
                    name: 'Failure Canary'
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.http.router.legacy_lyft_token.unauthorized.instance.count.rate, region=iad and asg=envoy and canary=true))'
                    name: 'Denied Canary'
                {% endif %}
              - title: bearer token auth status
                datasource: wavefront
                targets:
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.http.router.bearer_auth.ok.instance.count.rate, region=iad and asg=envoy))'
                    name: 'Success'
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.http.router.bearer_auth.error.instance.count.rate, region=iad and asg=envoy))'
                    name: 'Failure'
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.http.router.bearer_auth.unauthorized.instance.count.rate, region=iad and asg=envoy))'
                    name: 'Denied'
                {% if canary %}
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.http.router.bearer_auth.ok.instance.count.rate, region=iad and asg=envoy and canary=true))'
                    name: 'Success Canary'
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.http.router.bearer_auth.error.instance.count.rate, region=iad and asg=envoy and canary=true))'
                    name: 'Failure Canary'
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.http.router.bearer_auth..unauthorized.instance.count.rate, region=iad and asg=envoy and canary=true))'
                    name: 'Denied Canary'
                {% endif %}
              - title: auth timing
                datasource: wavefront
                targets:
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.cluster.auth.upstream_rq_time.instance.timer.p50, region=iad and asg=envoy))'
                    name: 'P50'
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.cluster.auth.upstream_rq_time.instance.timer.p95, region=iad and asg=envoy))'
                    name: 'P95'
                {% if canary %}
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.cluster.auth.upstream_rq_time.instance.timer.p50, region=iad and asg=envoy and canary=true))'
                    name: 'P50 Canary'
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.cluster.auth.upstream_rq_time.instance.timer.p95, region=iad and asg=envoy and canary=true))'
                    name: 'P95 Canary'
                {% endif %}
                y_formats:
                  - ms
                  - short
          - title: VPN AUTHENTICATION
            collapse: True
            panels:
              - title: vpn auth attempts
                datasource: wavefront
                targets:
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.auth.clientssl.vpnauth.auth_digest_match.instance.count.sum, region=iad and asg=envoy))'
                    name: 'Digest Match'
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.auth.clientssl.vpnauth.auth_digest_no_match.instance.count.sum, region=iad and asg=envoy))'
                    name: 'Digest Invalid Match'
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.auth.clientssl.vpnauth.auth_ip_white_list.instance.count.sum, region=iad and asg=envoy))'
                    name: 'IP White List Match'
                {% if canary %}
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.auth.clientssl.vpnauth.auth_digest_match.instance.count.sum, region=iad and asg=envoy and canary=true))'
                    name: 'Digest Match Canary'
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.auth.clientssl.vpnauth.auth_digest_no_match.instance.count.sum, region=iad and asg=envoy and canary=true))'
                    name: 'Digest Invalid Match Canary'
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.auth.clientssl.vpnauth.auth_ip_white_list.instance.count.sum, region=iad and asg=envoy and canary=true))'
                    name: 'IP White List Match Canary'
                {% endif %}
              - title: vpn auth principals
                datasource: wavefront
                targets:
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.auth.clientssl.vpnauth.total_principals.instance.gauge.mean, region=iad and asg=envoy))'
                    name: 'Total Principals'
                {% if canary %}
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.auth.clientssl.vpnauth.total_principals.instance.gauge.mean, region=iad and asg=envoy and canary=true))'
                    name: 'Total Principals Canary'
                {% endif %}
          - title: Rate Limit
            collapse: True
            panels:
              - title: Total Hits per minute
                datasource: wavefront
                targets:
                - target: align(1m, default(0, ts(production.app.ratelimit.service.rate_limit.envoy_front.*.total_hits.count.sum, asg=ratelimit)))
                  regexes:
                    - regex: "rate_limit\\.envoy_front\\.(.+)\\.total_hits"
                      replacement: total hits $1
              - title: Over limits per minute
                datasource: wavefront
                targets:
                  - target: align(1m, default(0, ts(production.app.ratelimit.service.rate_limit.envoy_front.*.over_limit.count.sum, asg=ratelimit)))
                    regexes:
                      - regex: "rate_limit\\.envoy_front\\.(.+)\\.over_limit"
                        replacement: over limit $1
              - title: Near limits per minute
                datasource: wavefront
                targets:
                  - target: align(1m, default(0, ts(production.app.ratelimit.service.rate_limit.envoy_front.*.near_limit.count.sum, asg=ratelimit)))
                    regexes:
                      - regex: "rate_limit\\.envoy_front\\.(.+)\\.near_limit"
                        replacement: near limit $1
          - title: RDS
            collapse: True
            panels:
              - title: RDS Listeners
                datasource: wavefront
                targets:
                  - target: align(1m, default(0, ts(production.infra.aws.ec2.asg.envoy.listener.0.0.0.0_931*.downstream_cx_total.count.sum)))
                    regexes:
                      - regex: "listener\\.0\\.0\\.0\\.0_(.+)\\.downstream_cx_total"
                        replacement: Total Cx $1
                  - target: align(1m, default(0, ts(production.infra.aws.ec2.asg.envoy.listener.0.0.0.0_931*.downstream_cx_destroy.count.sum)))
                    regexes:
                      - regex: "listener\\.0\\.0\\.0\\.0_(.+)\\.downstream_cx_destroy"
                        replacement: Destroy Cx $1
                  - target: align(1m, default(0, ts(production.infra.aws.ec2.asg.envoy.listener.0.0.0.0_931*.downstream_cx_active.count.sum)))
                    regexes:
                      - regex: "listener\\.0\\.0\\.0\\.0_(.+)\\.downstream_cx_active"
                        replacement: Active Cx $1
              - title: RDS Listener Errors
                datasource: wavefront
                targets:
                  - target: align(1m, default(0, ts(production.infra.aws.ec2.asg.envoy.listener.0.0.0.0_931*.downstream_cx_proxy_proto_error.count.sum)))
                    regexes:
                      - regex: "listener\\.0\\.0\\.0\\.0_(.+)\\.downstream_cx_proxy_proto_error"
                        replacement: Proxy Proto Cx Error $1
              - title: RDS Stats
                datasource: wavefront
                targets:
                  - target: align(1m, default(0, ts(production.infra.aws.ec2.asg.envoy.http.router.rds.*.update_attempt.count.sum, asg=envoy and region=iad)))
                    name: 'Update Attempt'
                  - target: align(1m, default(0, ts(production.infra.aws.ec2.asg.envoy.http.router.rds.*.config_reload.count.sum, asg=envoy and region=iad)))
                    name: 'Config Reload'
                  - target: align(1m, default(0, ts(production.infra.aws.ec2.asg.envoy.http.router.rds.*.update_success.count.sum, asg=envoy and region=iad)))
                    name: 'Update Success'
              - title: RDS Error Stats
                datasource: wavefront
                targets:
                  - target: align(1m, default(0, ts(production.infra.aws.ec2.asg.envoy.http.router.rds.*.update_empty.count.sum, asg=envoy and region=iad)))
                    name: 'Update Empty'
                  - target: align(1m, default(0, ts(production.infra.aws.ec2.asg.envoy.http.router.rds.*.update_failure.count.sum, asg=envoy and region=iad)))
                    name: 'Update Failure'
                  - target: align(1m, default(0, ts(production.infra.aws.ec2.asg.envoy.http.router.rds.*.update_rejected.count.sum, asg=envoy and region=iad)))
                    name: 'Update Rejected'
          {{ envoymanager_front_envoy_rds(["staging","canary","production"], "*", canary, "production", True, False) }}
          {{ system_health('envoy', regions, canary) }}
          {{ sla_per_service_machine_stats('envoy', info, False, 'production') | indent(10) }}
          - title: SSL
            panels:
              - title: Days Until First Cert Expires
                datasource: wavefront
                targets:
                {% for region in regions %}
                  - target: 'rawmin(ts(production.infra.aws.ec2.asg.envoy.server.days_until_first_cert_expiring.instance.gauge.mean, region={{region}} and asg=envoy))'
                    name: '{{region}}'
                {% endfor %}
                y_formats:
                  - short
{% endfor %}
